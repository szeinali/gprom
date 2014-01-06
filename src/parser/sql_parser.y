/*
 * Sql_Parser.y
 *     This is a bison file which contains grammar rules to parse SQLs
 */



%{
#include "common.h"
#include "mem_manager/mem_mgr.h"
#include "model/expression/expression.h"
#include "model/list/list.h"
#include "model/node/nodetype.h"
#include "model/query_block/query_block.h"
#include "parser/parse_internal.h"
#include "log/logger.h"

#define RULELOG(grule) \
    { \
        TRACE_LOG("Parsing grammer rule <%s>", #grule); \
    }
    
#undef free

Node *bisonParseResult = NULL;
%}

%union {
    /* 
     * Declare some C structure those will be used as data type
     * for various tokens used in grammar rules.
     */
     Node *node;
     List *list;
     char *stringVal;
     int intVal;
     double floatVal;
}

/*
 * Declare tokens for name and literal values
 * Declare tokens for user variables
 */
%token <intVal> intConst
%token <floatVal> floatConst
%token <stringVal> stringConst
%token <stringVal> identifier
%token <stringVal> '+' '-' '*' '/' '%' '^' '&' '|' '!' comparisonOps ')' '(' '='

/*
 * Tokens for in-built keywords
 *        Currently keywords related to basic query are considered.
 *        Later on other keywords will be added.
 */
%token <stringVal> SELECT INSERT UPDATE DELETE
%token <stringVal> PROVENANCE OF BASERELATION SCN TIMESTAMP
%token <stringVal> FROM
%token <stringVal> AS
%token <stringVal> WHERE
%token <stringVal> DISTINCT
%token <stringVal> STARALL
%token <stringVal> AND OR LIKE NOT IN ISNULL BETWEEN EXCEPT EXISTS
%token <stringVal> AMMSC NULLVAL ALL ANY IS SOME
%token <stringVal> UNION INTERSECT MINUS
%token <stringVal> INTO VALUES HAVING GROUP ORDER BY LIMIT SET
%token <stringVal> INT BEGIN_TRANS COMMIT_TRANS ROLLBACK_TRANS

%token <stringVal> DUMMYEXPR

/* Keywords for Join queries */
%token <stringVal> JOIN NATURAL LEFT RIGHT OUTER INNER CROSS ON USING FULL 

/*
 * Declare token for operators specify their associativity and precedence
 */
%left UNION INTERSECT MINUS

/* Logical operators */
%left '|'
%left XOR
%left '&'
/* what is that? %right ':=' */
%left '!'

/* Comparison operator */
%left comparisonOps
%right NOT
%left AND OR
%right ISNULL
%nonassoc  LIKE IN  BETWEEN

/* Arithmetic operators : FOR TESTING */
%nonassoc DUMMYEXPR
%left '+' '-'
%left '*' '/' '%'
%left '^'
%nonassoc '(' ')'

%left NATURAL JOIN CROSS LEFT FULL RIGHT INNER

/*
 * Types of non-terminal symbols
 */
%type <node> stmt provStmt dmlStmt queryStmt
%type <node> selectQuery deleteQuery updateQuery insertQuery subQuery setOperatorQuery
        // Its a query block model that defines the structure of query.
%type <list> selectClause optionalFrom fromClause exprList clauseList optionalGroupBy optionalOrderBy setClause// select and from clauses are lists
             insertList stmtList identifierList optionalAttrAlias
%type <node> selectItem fromClauseItem fromJoinItem optionalFromProv optionalAlias optionalDistinct optionalWhere optionalLimit optionalHaving
             //optionalReruning optionalGroupBy optionalOrderBy optionalLimit
%type <node> expression constant attributeRef sqlFunctionCall whereExpression setExpression
%type <node> binaryOperatorExpression unaryOperatorExpression
%type <node> joinCond
%type <node> optionalProvAsOf
%type <stringVal> optionalAll nestedSubQueryOperator optionalNot fromString
%type <stringVal> joinType transactionIdentifier

%start stmtList

%%

/* Rule for all types of statements */
stmtList: 
		stmt ';'
			{ 
				RULELOG("stmtList::stmt"); 
				$$ = singleton($1);
				bisonParseResult = (Node *) $$;	 
			}
		| stmtList stmt ';' 
			{
				RULELOG("stmtlist::stmtList::stmt");
				$$ = appendToTailOfList($1, $2);	
				bisonParseResult = (Node *) $$; 
			}
	;

stmt: 
        dmlStmt    // DML statement can be select, update, insert, delete
        {
            RULELOG("stmt::dmlStmt");
            $$ = $1;
        }
		| queryStmt
        {
            RULELOG("stmt::queryStmt");
            $$ = $1;
        }
        | transactionIdentifier
        {
            RULELOG("stmt::transactionIdentifier");
            $$ = (Node *) createTransactionStmt($1);
        }
    ;

/*
 * Rule to parse all DML queries.
 */
dmlStmt:
        insertQuery        { RULELOG("dmlStmt::insertQuery"); }
        | deleteQuery        { RULELOG("dmlStmt::deleteQuery"); }
        | updateQuery        { RULELOG("dmlStmt::updateQuery"); }
    ;

/*
 * Rule to parse all types projection queries.
 */
queryStmt:
		'(' queryStmt ')'	{ RULELOG("queryStmt::bracketedQuery"); $$ = $2; }
		| selectQuery        { RULELOG("queryStmt::selectQuery"); }
		| provStmt        { RULELOG("queryStmt::provStmt"); }
		| setOperatorQuery        { RULELOG("queryStmt::setOperatorQuery"); }
    ;

transactionIdentifier:
        BEGIN_TRANS        { RULELOG("transactionIdentifier::BEGIN"); $$ = strdup("TRANSACTION_BEGIN"); }
        | COMMIT_TRANS        { RULELOG("transactionIdentifier::COMMIT"); $$ = strdup("TRANSACTION_COMMIT"); }
        | ROLLBACK_TRANS        { RULELOG("transactionIdentifier::ROLLBACK"); $$ = strdup("TRANSACTION_ABORT"); }
    ;

/* 
 * Rule to parse a query asking for provenance
 */
provStmt: 
        PROVENANCE optionalProvAsOf OF '(' stmt ')'
        {
            RULELOG("provStmt::stmt");
            Node *stmt = $5;
	    	ProvenanceStmt *p = createProvenanceStmt(stmt);
		    p->inputType = isQBUpdate(stmt) ? PROV_INPUT_UPDATE : PROV_INPUT_QUERY;
		    p->provType = PROV_PI_CS;
		    p->asOf = (Node *) $2;
            $$ = (Node *) p;
        }
	| PROVENANCE optionalProvAsOf OF '(' stmtList ')'
		{
			RULELOG("provStmt::stmtlist");
			ProvenanceStmt *p = createProvenanceStmt((Node *) $5);
			p->inputType = PROV_INPUT_UPDATE_SEQUENCE;
			p->provType = PROV_PI_CS;
			p->asOf = (Node *) $2;
			$$ = (Node *) p;
		}
    ;
    
optionalProvAsOf:
		/* empty */			{ RULELOG("optionalProvAsOf::EMPTY"); $$ = NULL; }
		| AS OF SCN intConst
		{
			RULELOG("optionalProvAsOf::SCN");
			$$ = (Node *) createConstInt($4);
		}
		| AS OF TIMESTAMP stringConst
		{
			RULELOG("optionalProvAsOf::TIMESTAMP");
			$$ = (Node *) createConstString($4);
		}

/*
 * Rule to parse delete query
 */ 
deleteQuery: 
         DELETE fromString identifier WHERE whereExpression /* optionalReturning */
         { 
             RULELOG("deleteQuery");
             $$ = (Node *) createDelete($3, $5);
         }
/* No provision made for RETURNING statements in delete clause */
    ;

fromString:
        /* Empty */        { RULELOG("fromString::NULL"); $$ = NULL; }
        | FROM        { RULELOG("fromString::FROM"); $$ = $1; }
    ;

         
//optionalReturning:
/*         Empty         { RULELOG("optionalReturning::NULL"); $$ = NULL; }
        | RETURNING expression INTO identifier
            { RULELOG("optionalReturning::RETURNING"); }
    ; */

/*
 * Rules to parse update query
 */
updateQuery:
        UPDATE identifier SET setClause optionalWhere
            { 
                RULELOG(updateQuery); 
                $$ = (Node *) createUpdate($2, $4, $5); 
            }
    ;

setClause:
        setExpression
            {
                RULELOG("setClause::setExpression");
                $$ = singleton($1);
            }
        | setClause ',' setExpression
            {
                RULELOG("setClause::setClause::setExpression");
                $$ = appendToTailOfList($1, $3);
            }
    ;

setExpression:
        attributeRef comparisonOps expression
            {
                if (!strcmp($2,"=")) {
                    RULELOG("setExpression::attributeRef::expression");
                    List *expr = singleton($1);
                    expr = appendToTailOfList(expr, $3);
                    $$ = (Node *) createOpExpr($2, expr);
                }
            }
        | attributeRef comparisonOps subQuery 
            {
                if (!strcmp($2, "=")) {
                    RULELOG("setExpression::attributeRef::queryStmt");
                    List *expr = singleton($1);
                    expr = appendToTailOfList(expr, $3);
                    $$ = (Node *) createOpExpr($2, expr);
                }
            }
    ;

/*
 * Rules to parse insert query
 */
insertQuery:
        INSERT INTO identifier VALUES '(' insertList ')'
            { 
            	RULELOG("insertQuery::insertList"); 
            	$$ = (Node *) createInsert($3,(Node *) $6, NULL); 
        	} 
        | INSERT INTO identifier queryStmt
            { 
                RULELOG("insertQuery::queryStmt");
                $$ = (Node *) createInsert($3, $4, NULL);
            }
    ;

insertList:
        constant
            { 
            	RULELOG("insertList::constant");
            	$$ = singleton($1); 
            }
        | identifier
            {
                RULELOG("insertList::IDENTIFIER");
                $$ = singleton(createAttributeReference($1));
            }
        | insertList ',' identifier
            { 
                RULELOG("insertList::insertList::::IDENTIFIER");
                $$ = appendToTailOfList($1, createAttributeReference($3));
            }
        | insertList ',' constant
            { 
            	RULELOG("insertList::insertList::constant");
            	$$ = appendToTailOfList($1, $3);
            }
/* No Provision made for this type of insert statements */
    ;


/*
 * Rules to parse set operator queries
 */

setOperatorQuery:     // Need to look into createFunction
        queryStmt INTERSECT queryStmt
            {
                RULELOG("setOperatorQuery::INTERSECT");
                $$ = (Node *) createSetQuery($2, FALSE, $1, $3);
            }
        | queryStmt MINUS queryStmt 
            {
                RULELOG("setOperatorQuery::MINUS");
                $$ = (Node *) createSetQuery($2, FALSE, $1, $3);
            }
        | queryStmt UNION optionalAll queryStmt
            {
                RULELOG("setOperatorQuery::UNION");
                $$ = (Node *) createSetQuery($2, ($3 != NULL), $1, $4);
            }
    ;

optionalAll:
        /* Empty */ { RULELOG("optionalAll::NULL"); $$ = NULL; }
        | ALL        { RULELOG("optionalAll::ALLTRUE"); $$ = $1; }
    ;

/*
 * Rule to parse select query
 * Currently it will parse following type of select query:
 *             'SELECT [DISTINCT clause] selectClause FROM fromClause WHERE whereClause'
 */
selectQuery: 
        SELECT optionalDistinct selectClause optionalFrom optionalWhere optionalGroupBy optionalHaving optionalOrderBy optionalLimit
            {
                RULELOG(selectQuery);
                QueryBlock *q =  createQueryBlock();
                
                q->distinct = $2;
                q->selectClause = $3;
                q->fromClause = $4;
                q->whereClause = $5;
                q->groupByClause = $6;
                q->havingClause = $7;
                q->orderByClause = $8;
                q->limitClause = $9;
                
                $$ = (Node *) q; 
            }
    ;


/*
 * Rule to parse optional distinct clause.
 */ 
optionalDistinct: 
        /* empty */                     { RULELOG("optionalDistinct::NULL"); $$ = NULL; }
        | DISTINCT
            {
                RULELOG("optionalDistinct::DISTINCT");
                $$ = (Node *) createDistinctClause(NULL);
            }
        | DISTINCT ON '(' exprList ')'
            {
                RULELOG("optionalDistinct::DISTINCT::exprList");
                $$ = (Node *) createDistinctClause($4);
            }
    ;
                        

/*
 * Rule to parse the select clause items.
 */
selectClause: 
        selectItem
             {
                RULELOG("selectClause::selectItem"); $$ = singleton($1);
            }
        | selectClause ',' selectItem
            {
                RULELOG("selectClause::selectClause::selectItem");
                $$ = appendToTailOfList($1, $3); 
            }
    ;

selectItem:
         expression                            
             {
                 RULELOG("selectItem::expression"); 
                 $$ = (Node *) createSelectItem(NULL, $1); 
             }
         | expression AS identifier             
             {
                 RULELOG("selectItem::expression::identifier"); 
                 $$ = (Node *) createSelectItem($3, $1);
             }
         | '*'              
			{ 
         		RULELOG("selectItem::*"); 
         		$$ = (Node *) createSelectItem(strdup("*"), NULL); 
     		}
         | identifier '.' '*' 
         	{ 
         		RULELOG("selectItem::*"); 
     			$$ = (Node *) createSelectItem(CONCAT_STRINGS($1,".*"), NULL); 
 			}
    ; 

/*
 * Rule to parse an expression list
 */
exprList: 
        expression        { RULELOG("exprList::SINGLETON"); $$ = singleton($1); }
        | exprList ',' expression
             {
                  RULELOG("exprList::exprList::expression");
                  $$ = appendToTailOfList($1, $3);
             }
    ;
         

/*
 * Rule to parse expressions used in various lists
 */
expression:
		'(' expression ')'				{ RULELOG("expression::bracked"); $$ = $2; } 
		| constant     				   	{ RULELOG("expression::constant"); }
        | attributeRef         		  	{ RULELOG("expression::attributeRef"); }
        | binaryOperatorExpression		{ RULELOG("expression::binaryOperatorExpression"); } 
        | unaryOperatorExpression       { RULELOG("expression::unaryOperatorExpression"); }
        | sqlFunctionCall        		{ RULELOG("expression::sqlFunctionCall"); }
/*        | '(' queryStmt ')'       { RULELOG ("expression::subQuery"); $$ = $2; } */
/*        | STARALL        { RULELOG("expression::STARALL"); } */
    ;
            
/*
 * Constant parsing
 */
constant: 
        intConst            { RULELOG("constant::INT"); $$ = (Node *) createConstInt($1); }
        | floatConst        { RULELOG("constant::FLOAT"); $$ = (Node *) createConstFloat($1); }
        | stringConst        { RULELOG("constant::STRING"); $$ = (Node *) createConstString($1); }
    ;
            
/*
 * Parse attribute reference
 */
attributeRef: 
        identifier         { RULELOG("attributeRef::IDENTIFIER"); $$ = (Node *) createAttributeReference($1); }

/* HELP HELP ??
       Need helper function support for attribute list in expression.
       For e.g.
           SELECT attr FROM tab
           WHERE
              (col1, col2) = (SELECT cl1, cl2 FROM tab2)
       SolQ: Can we use selectItem function here?????
*/
    ;

/*
 * Parse operator expression
 */
 
binaryOperatorExpression: 

    /* Arithmatic Operations */
        expression '+' expression
            {
                RULELOG("binaryOperatorExpression:: '+' ");
                List *expr = singleton($1);
                expr = appendToTailOfList(expr, $3);
                $$ = (Node *) createOpExpr($2, expr);
            }
        | expression '-' expression
            {
                RULELOG("binaryOperatorExpression:: '-' ");
                List *expr = singleton($1);
                expr = appendToTailOfList(expr, $3);
                $$ = (Node *) createOpExpr($2, expr);
            }
        | expression '*' expression
            {
                RULELOG("binaryOperatorExpression:: '*' ");
                List *expr = singleton($1);
                expr = appendToTailOfList(expr, $3);
                $$ = (Node *) createOpExpr($2, expr);
            }
        | expression '/' expression
            {
                RULELOG("binaryOperatorExpression:: '/' ");
                List *expr = singleton($1);
                expr = appendToTailOfList(expr, $3);
                $$ = (Node *) createOpExpr($2, expr);
            }
        | expression '%' expression
            {
                RULELOG("binaryOperatorExpression:: '%' ");
                List *expr = singleton($1);
                expr = appendToTailOfList(expr, $3);
                $$ = (Node *) createOpExpr($2, expr);
            }
        | expression '^' expression
            {
                RULELOG("binaryOperatorExpression:: '^' ");
                List *expr = singleton($1);
                expr = appendToTailOfList(expr, $3);
                $$ = (Node *) createOpExpr($2, expr);
            }

    /* Binary operators */
        | expression '&' expression
            {
                RULELOG("binaryOperatorExpression:: '&' ");
                List *expr = singleton($1);
                expr = appendToTailOfList(expr, $3);
                $$ = (Node *) createOpExpr($2, expr);
            }
        | expression '|' expression
            {
                RULELOG("binaryOperatorExpression:: '|' ");
                List *expr = singleton($1);
                expr = appendToTailOfList(expr, $3);
                $$ = (Node *) createOpExpr($2, expr);
            }

    /* Comparison Operators */
        | expression comparisonOps expression
            {
                RULELOG("binaryOperatorExpression::comparisonOps");
                List *expr = singleton($1);
                expr = appendToTailOfList(expr, $3);
                $$ = (Node *) createOpExpr($2, expr);
            }
    ;

unaryOperatorExpression:
        '!' expression
            {
                RULELOG("unaryOperatorExpression:: '!' ");
                List *expr = singleton($2);
                $$ = (Node *) createOpExpr($1, expr);
            }
    ;
    
/*
 * Rule to parse function calls
 */
sqlFunctionCall: 
        identifier '(' exprList ')'          
            {
                RULELOG("sqlFunctionCall::IDENTIFIER::exprList"); 
                $$ = (Node *) createFunctionCall($1, $3); 
            }
    ;

/*
 * Rule to parse from clause
 *            Currently implemented for basic from clause.
 *            Later on other forms of from clause will be added.
 */
optionalFrom: 
        /* empty */              { RULELOG("optionalFrom::NULL"); $$ = NULL; }
        | FROM fromClause        { RULELOG("optionalFrom::fromClause"); $$ = $2; }
    ;
            
fromClause: 
        fromClauseItem
            {
                RULELOG("fromClause::fromClauseItem");
                $$ = singleton($1);
            }
        | fromClause ',' fromClauseItem
            {
                RULELOG("fromClause::fromClause::fromClauseItem");
                $$ = appendToTailOfList($1, $3);
            }
    ;


fromClauseItem:
        identifier optionalFromProv
            {
                RULELOG("fromClauseItem");
				FromItem *f = createFromTableRef(NULL, NIL, $1);
				f->provInfo = (FromProvInfo *) $2;
                $$ = (Node *) f;
            }
        | identifier optionalAlias
            {
                RULELOG("fromClauseItem");
                FromItem *f = createFromTableRef(((FromItem *) $2)->name, 
						((FromItem *) $2)->attrNames, $1);
				f->provInfo = ((FromItem *) $2)->provInfo;
                $$ = (Node *) f;
            }
            
        | subQuery optionalFromProv
            {
                RULELOG("fromClauseItem::subQuery");
                FromItem *f = (FromItem *) $1;
                f->provInfo = (FromProvInfo *) $2;
                $$ = $1;
            }
        | subQuery optionalAlias
            {
                RULELOG("fromClauseItem::subQuery");
                FromSubquery *s = (FromSubquery *) $1;
                s->from.name = ((FromItem *) $2)->name;
                s->from.attrNames = ((FromItem *) $2)->attrNames;
                s->from.provInfo = ((FromItem *) $2)->provInfo;
                $$ = (Node *) s;
            }
        | fromJoinItem
        	{
        		FromItem *f;
        		RULELOG("fromClauseItem::fromJoinItem");
        		f = (FromItem *) $1;
        		f->name = NULL;
        		$$ = (Node *) f;
        	}
       	 | '(' fromJoinItem ')' optionalAlias
        	{
        		FromItem *f;
        		RULELOG("fromClauseItem::fromJoinItem");
        		f = (FromItem *) $2;
        		f->name = ((FromItem *) $4)->name;
                f->attrNames = ((FromItem *) $4)->attrNames;
                f->provInfo = ((FromItem *) $4)->provInfo;
        		$$ = (Node *) f;
        	}
    ;

subQuery:
        '(' queryStmt ')'
            {
                RULELOG("subQuery::queryStmt");
                $$ = (Node *) createFromSubquery(NULL, NULL, $2);
            }
    ;

identifierList:
		identifier { $$ = singleton($1); }
		| identifierList ',' identifier { $$ = appendToTailOfList($1, $3); }
	;
	
fromJoinItem:
		'(' fromJoinItem ')' 			{ $$ = $2; }
        | fromClauseItem NATURAL JOIN fromClauseItem 
			{
                RULELOG("fromJoinItem::NATURAL");
                $$ = (Node *) createFromJoin(NULL, NIL, (FromItem *) $1, 
						(FromItem *) $4, "JOIN_INNER", "JOIN_COND_NATURAL", 
						NULL);
          	}
		| fromClauseItem NATURAL joinType JOIN fromClauseItem 
			{
                RULELOG("fromJoinItem::NATURALjoinType");
                $$ = (Node *) createFromJoin(NULL, NIL, (FromItem *) $1, 
                		(FromItem *) $5, $3, "JOIN_COND_NATURAL", NULL);
          	}
     	| fromClauseItem CROSS JOIN fromClauseItem 
        	{
				RULELOG("fromJoinItem::CROSS JOIN");
                $$ = (Node *) createFromJoin(NULL, NIL, (FromItem *) $1, 
                		(FromItem *) $4, "JOIN_CROSS", "JOIN_COND_ON", NULL);
          	}
     	| fromClauseItem joinType JOIN fromClauseItem joinCond 
        	{
				RULELOG("fromJoinItem::JOIN::joinType::joinCond");
				char *condType = (isA($5,List)) ? "JOIN_COND_USING" : 
						"JOIN_COND_ON";
                $$ = (Node *) createFromJoin(NULL, NIL, (FromItem *) $1, 
                		(FromItem *) $4, $2, condType, $5);
          	}
     	| fromClauseItem JOIN fromClauseItem joinCond
        	{
				RULELOG("fromJoinItem::JOIN::joinCond");
				char *condType = (isA($4,List)) ? "JOIN_COND_USING" : 
						"JOIN_COND_ON"; 
                $$ = (Node *) createFromJoin(NULL, NIL, (FromItem *) $1, 
                		(FromItem *) $3, "JOIN_INNER", 
                		condType, $4);
          	}
     ;
     
joinType:
		LEFT 			{ RULELOG("joinType::LEFT"); $$ = "JOIN_LEFT_OUTER"; }
		| LEFT OUTER 	{ RULELOG("joinType::LEFT OUTER"); $$ = "JOIN_LEFT_OUTER"; }
		| RIGHT 		{ RULELOG("joinType::RIGHT "); $$ = "JOIN_RIGHT_OUTER"; }
		| RIGHT OUTER  	{ RULELOG("joinType::RIGHT OUTER"); $$ = "JOIN_RIGHT_OUTER"; }
		| FULL OUTER  	{ RULELOG("joinType::FULL OUTER"); $$ = "JOIN_FULL_OUTER"; }
		| FULL 	  		{ RULELOG("joinType::FULL"); $$ = "JOIN_FULL_OUTER"; }
		| INNER  		{ RULELOG("joinType::INNER"); $$ = "JOIN_INNER"; }
	;

joinCond:
		USING '(' identifierList ')' { $$ = (Node *) $3; }
		| ON whereExpression			 { $$ = $2; }
	;

optionalAlias:
        optionalFromProv identifier optionalAttrAlias      
			{
				RULELOG("optionalAlias::identifier"); 
				FromItem *f = createFromItem($2,$3);
 				f->provInfo = (FromProvInfo *) $1;
				$$ = (Node *) f;
			}
        | optionalFromProv AS identifier optionalAttrAlias       
			{ 
				RULELOG("optionalAlias::identifier"); 
				FromItem *f = createFromItem($3,$4);
 				f->provInfo = (FromProvInfo *) $1; 
				$$ = (Node *) f;
			}
    ;
    
optionalFromProv:
		/* empty */ { RULELOG("optionalFromProv::empty"); $$ = NULL; }
		| BASERELATION 
			{
				RULELOG("optionalFromProv");
				FromProvInfo *p = makeNode(FromProvInfo);
				p->baserel = TRUE;
				p->userProvAttrs = NIL;				 
				$$ = (Node *) p; 
			}
		| PROVENANCE '(' identifierList ')'
			{
				RULELOG("optionalFromProv::userProvAttr");
				FromProvInfo *p = makeNode(FromProvInfo);
				p->baserel = FALSE;
				p->userProvAttrs = $3;				 
				$$ = (Node *) p; 
			}
	;
    
optionalAttrAlias:
		/* empty */ { RULELOG("optionalAttrAlias::empty"); $$ = NULL; }
		| '(' identifierList ')' 
			{ 
				RULELOG("optionalAttrAlias::identifierList"); $$ = $2; 
			}
    ;
    
/*
 * Rule to parse the where clause.
 */
optionalWhere: 
        /* empty */             { RULELOG("optionalWhere::NULL"); $$ = NULL; }
        | WHERE whereExpression        { RULELOG("optionalWhere::whereExpression"); $$ = $2; }
    ;

whereExpression:
		'(' whereExpression ')' { RULELOG("where::brackedWhereExpression"); $$ = $2; } %prec DUMMYEXPR
        | expression        { RULELOG("whereExpression::expression"); $$ = $1; } %prec '+'
        | NOT whereExpression
            {
                RULELOG("whereExpression::NOT");
                List *expr = singleton($2);
                $$ = (Node *) createOpExpr($1, expr);
            }
        | whereExpression AND whereExpression	
            {
                RULELOG("whereExpression::AND");
                List *expr = singleton($1);
                expr = appendToTailOfList(expr, $3);
                $$ = (Node *) createOpExpr($2, expr);
            }
        | whereExpression OR whereExpression
            {
                RULELOG("whereExpression::AND");
                List *expr = singleton($1);
                expr = appendToTailOfList(expr, $3);
                $$ = (Node *) createOpExpr($2, expr);
            }
        | whereExpression LIKE whereExpression
            {
                RULELOG("whereExpression::AND");
                List *expr = singleton($1);
                expr = appendToTailOfList(expr, $3);
                $$ = (Node *) createOpExpr($2, expr);
            }
        | whereExpression BETWEEN expression AND expression
            {
                RULELOG("whereExpression::BETWEEN-AND");
                List *expr = singleton($1);
                expr = appendToTailOfList(expr, $3);
                expr = appendToTailOfList(expr, $5);
                $$ = (Node *) createOpExpr($2, expr);
            }
        | expression comparisonOps nestedSubQueryOperator '(' queryStmt ')'
            {
                RULELOG("whereExpression::comparisonOps::nestedSubQueryOperator::Subquery");
                $$ = (Node *) createNestedSubquery($3, $1, $2, $5);
            }
        | expression comparisonOps '(' queryStmt ')'
            {
                RULELOG("whereExpression::comparisonOps::Subquery");
                List *expr = singleton($1);
                expr = appendToTailOfList(expr, $4);
                $$ = (Node *) createOpExpr($2, expr);
            }
        | expression optionalNot IN '(' queryStmt ')'
            {
                if ($2 == NULL)
                {
                    RULELOG("whereExpression::IN");
                    $$ = (Node *) createNestedSubquery("ANY", $1, "=", $5);
                }
                else
                {
                    RULELOG("whereExpression::NOT::IN");
                    $$ = (Node *) createNestedSubquery("ALL",$1, "<>", $5);
                }
            }
        | /* optionalNot */ EXISTS '(' queryStmt ')'
            {
                /* if ($1 == NULL)
                { */
                    RULELOG("whereExpression::EXISTS");
                    $$ = (Node *) createNestedSubquery($1, NULL, NULL, $3);
               /*  }
                else
                {
                    RULELOG("whereExpression::EXISTS::NOT");
                    $$ = (Node *) createNestedSubquery($2, NULL, "<>", $4);
                } */
            }
    ;

nestedSubQueryOperator:
        ANY { RULELOG("nestedSubQueryOperator::ANY"); $$ = $1; }
        | ALL { RULELOG("nestedSubQueryOperator::ALL"); $$ = $1; }
        | SOME { RULELOG("nestedSubQueryOperator::SOME"); $$ = "ANY"; }
    ;

optionalNot:
        /* Empty */    { RULELOG("optionalNot::NULL"); $$ = NULL; }
        | NOT    { RULELOG("optionalNot::NOT"); $$ = $1; }
    ;

optionalGroupBy:
        /* Empty */        { RULELOG("optionalGroupBy::NULL"); $$ = NULL; }
        | GROUP BY clauseList      { RULELOG("optionalGroupBy::GROUPBY"); $$ = $3; }
    ;

optionalHaving:
        /* Empty */        { RULELOG("optionalOrderBy:::NULL"); $$ = NULL; }
        | HAVING sqlFunctionCall comparisonOps expression
            { 
                RULELOG("optionalHaving::HAVING"); 
                List *expr = singleton($2);
                expr = appendToTailOfList(expr, $4);
                $$ = (Node *) createOpExpr($3, expr);
            }
    ;

optionalOrderBy:
        /* Empty */        { RULELOG("optionalOrderBy:::NULL"); $$ = NULL; }
        | ORDER BY clauseList       { RULELOG("optionalOrderBy::ORDERBY"); $$ = $3; }
    ;

optionalLimit:
        /* Empty */        { RULELOG("optionalLimit::NULL"); $$ = NULL; }
        | LIMIT constant        { RULELOG("optionalLimit::CONSTANT"); $$ = $2;}
    ;

clauseList:
        attributeRef
            {
                RULELOG("clauseList::attributeRef");
                $$ = singleton($1);
            }
        | clauseList ',' attributeRef
            {
                RULELOG("clauseList::clauseList::attributeRef");
                $$ = appendToTailOfList($1, $3);
            }
        | constant
            {
                RULELOG("clauseList::constant");
                $$ = singleton($1);
            }
        | clauseList ',' constant
            {
                RULELOG("clauseList::clauseList::attributeRef");
                $$ = appendToTailOfList($1, $3);
            }
    ;


%%



/* FUTURE WORK 

PRIORITIES
7)
4)
1)

EXHAUSTIVE LIST
1. Implement support for Case when statemets for all type of queries.
2. Implement support for RETURNING statement in DELETE queries.
3. Implement support for column list like (col1, col2, col3). 
   Needed in insert queries, select queries where conditions etc.
4. Implement support for Transactions.
5. Implement support for Create queries.
6. Implement support for windowing functions.
7. Implement support for AS OF (timestamp) modifier of a table reference
8. Implement support for casting expressions
9. Implement support for IN array expressions like a IN (1,2,3,4,5)
*/
