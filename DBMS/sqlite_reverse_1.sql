/*
 * This is a script to test reverse engineering of SQLite 3 scripts.
 * In some places, matching the output of ".fullschema";
 * in some others, trying to match possible syntax.
 */

CREATE TABLE one (c int);
CREATE TABLE two (d text, primary key (d));

/* ------------------------------------- */
/* table constraints */

/* TODO */

/* ------------------------------------- */
/* column constraints */

/* TODO */

/* ------------------------------------- */
/* temporary tables */

create temp table temp1 (a int);

create temporary table temp2 (a int);

create table temp.temp3 (a int);

/* ------------------------------------- */
/* views */

/* TODO */

/* ------------------------------------- */
/* triggers */

/* TODO */
