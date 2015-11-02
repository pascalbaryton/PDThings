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
   b foreign key references three(a)
      on update cascade
      on delete set null
      deferrable initially immediate
);

/* ------------------------------------- */
/* indexes */

create table index1 (a primary key,b,c,d);

create index index1_one on index1(b);
create index if not exist index1_two on index1(c,b);
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
create view v1v2 if not exists as select a,b from v1;
-- require SQLite 3.9+
create view v1v2 (a,bc) as select a,count(*) from v1 group by a;

/* ------------------------------------- */
/* virtual table */

create virtual table vt1 using foo(a,b);

/* ------------------------------------- */
/* triggers */

create table tr1 (a);
create table tr2 (a);

create trigger tr1t1
before delete on tr1
begin insert into tr2(a) select a from new; end;

create trigger tr1t2 if not exists
instead of update on tr1
begin
   insert into tr2(a) select a from new;
   update tr1 set a=new.a where a=old.a;
end;

/* ------------------------------------- */
/* database? */
/* attach, detach */

/* TODO */
