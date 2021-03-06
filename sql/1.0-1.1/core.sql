alter table cats add column historicalFacetOf int unsigned;
alter table cats add column historicalLeaf int unsigned default 0;
alter table cats add column summary text;
alter table cats add column keyWorks text;
alter table cats add column introductions text;
alter table cats add column summaryUpdated datetime;
alter table cats add column summaryChecked tinyint(1) unsigned default 1;
alter table cats add column advertiseSummary datetime;
alter table notices change column content content longtext;
create table api_users ( id int auto_increment primary key, secret varchar(255), created timestamp default CURRENT_TIMESTAMP );
drop table api_users;
alter table usersx add column apiKey varchar(255);
alter table cat_edits add column finished tinyint(1) unsigned default 0;
update cat_edits set finished = 1;
alter table cat_edits add index(finished);
