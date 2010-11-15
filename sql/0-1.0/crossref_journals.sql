create table crossref_journals ( id int unsigned auto_increment primary key, issn varchar(16), issn2 varchar(16), name varchar(255), doi varchar(255), lastIssue varchar(255), publisher varchar(255), subjects text, localName varchar(255) ) character set utf8;;
alter table crossref_journals add index( issn );
ALTER TABLE crossref_journals ADD FULLTEXT(name, subjects);
alter table crossref_journals add column harvestJournalId int;

