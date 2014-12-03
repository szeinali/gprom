/*-----------------------------------------------------------------------------
 *
 * rewriter.c
 *			  
 *		
 *		AUTHOR: lord_pretzel
 *
 *		
 *
 *-----------------------------------------------------------------------------
 */

#include "rewriter.h"

#include "common.h"
#include "mem_manager/mem_mgr.h"
#include "log/logger.h"
#include "configuration/option.h"
#include "configuration/option_parser.h"

#include "model/node/nodetype.h"
#include "model/query_block/query_block.h"
#include "model/query_operator/query_operator.h"
#include "model/query_operator/query_operator_model_checker.h"
#include "provenance_rewriter/prov_rewriter.h"
#include "analysis_and_translate/analyzer.h"
#include "analysis_and_translate/translator.h"
#include "sql_serializer/sql_serializer.h"
#include "operator_optimizer/operator_optimizer.h"
#include "parser/parser.h"
#include "metadata_lookup/metadata_lookup.h"
#include "operator_optimizer/cost_based_optimizer.h"

#include "instrumentation/timing_instrumentation.h"
#include "instrumentation/memory_instrumentation.h"

static char *rewriteParserOutput (Node *parse, boolean applyOptimizations);

int
initBasicModulesAndReadOptions (char *appName, char *appHelpText, int argc, char* argv[])
{
    initMemManager();
    mallocOptions();
    if(parseOption(argc, argv) != 0)
    {
        printOptionParseError(stdout);
        printOptionsHelp(stdout, appName, appHelpText, TRUE);
        return EXIT_FAILURE;
    }

    if (getBoolOption("help"))
    {
        printOptionsHelp(stdout, appName, appHelpText, FALSE);
        return EXIT_FAILURE;
    }

    initLogger();
    if (opt_memmeasure)
        setupMemInstrumentation();

    return EXIT_SUCCESS;
}

void
setupPluginsFromOptions(void)
{
    char *be = getStringOption("backend");
    char *pluginName = be;

    // setup parser - individual option overrides backend option
    if ((pluginName = getStringOption("plugin.parser")) != NULL)
        chooseParserPluginFromString(pluginName);
    else
        chooseParserPluginFromString(be);

    // setup metadata lookup - individual option overrides backend option
    initMetadataLookupPlugins();
    if ((pluginName = getStringOption("plugin.metadata")) != NULL)
        chooseMetadataLookupPluginFromString(pluginName);
    else
        chooseMetadataLookupPluginFromString(be);
    initMetadataLookupPlugin();

    // setup analyzer - individual option overrides backend option
    if ((pluginName = getStringOption("plugin.analyzer")) != NULL)
        chooseAnalyzerPluginFromString(pluginName);
    else
        chooseAnalyzerPluginFromString(be);

    // setup analyzer - individual option overrides backend option
    if ((pluginName = getStringOption("plugin.translator")) != NULL)
        chooseTranslatorPluginFromString(pluginName);
    else
        chooseTranslatorPluginFromString(be);

    // setup analyzer - individual option overrides backend option
    if ((pluginName = getStringOption("plugin.sqlserializer")) != NULL)
        chooseSqlserializerPluginFromString(pluginName);
    else
        chooseSqlserializerPluginFromString(be);
}

int
readOptionsAndIntialize(char *appName, char *appHelpText, int argc, char* argv[])
{
    int retVal;
    retVal = initBasicModulesAndReadOptions(appName, appHelpText, argc, argv);
    if (retVal != EXIT_SUCCESS)
        return retVal;

    setupPluginsFromOptions();

    return EXIT_SUCCESS;
}

int
shutdownApplication(void)
{
    INFO_LOG("shutdown plugins, logger, and memory manager");

    if (opt_memmeasure)
    {
        outputMemstats(FALSE);
        shutdownMemInstrumentation();
    }
    shutdownMetadataLookupPlugins();

    freeOptions();
    destroyMemManager();

    return EXIT_SUCCESS;
}

char *
rewriteQuery(char *input)
{
    Node *parse;
    char *result;

    parse = parseFromString(input);
    DEBUG_LOG("parser returned:\n\n<%s>", nodeToString(parse));

    result = rewriteParserOutput(parse, isRewriteOptionActivated(OPTION_OPTIMIZE_OPERATOR_MODEL));
    INFO_LOG("Rewritten SQL text from <%s>\n\n is <%s>", input, result);

//    OUT_TIMERS();

    return result;
}

char *
rewriteQueryFromStream (FILE *stream) {
    Node *parse;
    char *result;

    parse = parseStream(stream);
    DEBUG_LOG("parser returned:\n\n%s", nodeToString(parse));

    result = rewriteParserOutput(parse, isRewriteOptionActivated(OPTION_OPTIMIZE_OPERATOR_MODEL));
    INFO_LOG("Rewritten SQL text is <%s>", result);

//    OUT_TIMERS();

    return result;
}

char *
rewriteQueryWithOptimization(char *input)
{
    Node *parse;
    char *result;

    parse = parseFromString(input);
    DEBUG_LOG("parser returned:\n\n<%s>", nodeToString(parse));

    result = rewriteParserOutput(parse, TRUE);
    INFO_LOG("Rewritten SQL text from <%s>\n\n is <%s>", input, result);

    return result;
}

static char *
rewriteParserOutput (Node *parse, boolean applyOptimizations)
{

    char *rewrittenSQL = NULL;
    Node *oModel;
    //Node *rewrittenTree;

    START_TIMER("translation");
    oModel = translateParse(parse);
    DEBUG_LOG("translator returned:\n\n<%s>", beatify(nodeToString(oModel)));
    INFO_LOG("translator result as overview:\n\n%s", operatorToOverviewString(oModel));
    DOT_TO_CONSOLE(oModel);
    STOP_TIMER("translation");

    ASSERT_BARRIER(
        if (isA(oModel, List))
            FOREACH(QueryOperator,o,(List *) oModel)
                TIME_ASSERT(checkModel(o));
        else
            TIME_ASSERT(checkModel((QueryOperator *) oModel));
    )

    rewrittenSQL = doCostBasedOptimization(oModel, applyOptimizations);

    return rewrittenSQL;
}
