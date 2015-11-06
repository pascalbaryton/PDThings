/*
 * This is a script to test reverse engineering of SQLite 3 scripts.
 * In some places, matching the output of ".fullschema";
 * in some others, trying to match all possible syntax.
 */

CREATE TABLE one (c int,d);
CREATE TABLE two (d text, primary key (d));
CREATE INDEX one_d on one(d);

/* ------------------------------------- */
/* table constraints */

create table if not exists crt1 (a,b,c,d,
primary key(a,b)
);

create table crt2 (a,b,c,d,
primary key(a,b) on conflict ignore,
foreign key (a) references crt1(a)
      on update cascade
      on delete set null
      deferrable initially immediate
);

/* ------------------------------------- */
/* column constraints */

CREATE TABLE three
(
   a integer primary key asc on conflict ignore,
   b not null on conflict rollback,
   c default 3,
   d text unique on conflict fail,
   e check(e = 'a' or e = 'b'),
   f
);

CREATE TABLE four
(
   a integer primary key asc autoincrement,
   b
);

create table if not exists five (
   a integer primary key,
   b,
   c integer references four(a)
);

/* ------------------------------------- */
/* indexes */

create table index1 (a primary key,b,c,d);

create index index1_one on index1(b);
create index if not exists index1_two on index1(c,b);
create unique index index1_three on index1(d);

/* ------------------------------------- */
/* alter table */

create table alt1 (a int);
create table alt2 (a int);

alter table alt1 rename to alt1r;

alter table alt2 add column b;

alter table alt2 add c text;

alter table alt2 add d default 3;

/* ------------------------------------- */
/* temporary tables */

create temp table temp1 (a int);

create temporary table temp2 (a int);

create table temp.temp3 (a int);

/* ------------------------------------- */
/* views */

create table v1 (a,b);

create view v1v1 as select a from v1;
create view if not exists v1v2 as select a,b from v1;
-- requires SQLite 3.9+
create view v1v3 (a,bc) as select a,count(*) from v1 group by a;
create temp view v1v4 as select a from v1;
create temporary view v1v5 as select a from v1;

/* ------------------------------------- */
/* virtual table */

create virtual table vt1 using foo(a,b);

/* ------------------------------------- */
/* triggers */

create table tr1 (a);
create table tr2 (a);
create table tr3 (a);
create view tr4 as select a from tr2;

create trigger tr1t1
before delete on tr1
begin insert into tr2(a) select a from new; end;

/*
 the docs are not clear on this question,
    but (looking at source code) INSTEAD OF triggers are only for views
create trigger if not exists tr1t2
instead of update on tr1
begin
   insert into tr2(a) select a from new;
   update tr3 set a=new.a where a=old.a;
end;
*/

create trigger tr4t1
instead of insert on tr4
begin
   insert into tr1(a) values (new.a);
end;

/* ------------------------------------- */
/* database? */
/* attach, detach */

/* TODO */
