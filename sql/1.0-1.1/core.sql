alter table cats add column historicalFacetOf int unsigned;
alter table cats add column historicalLeaf int unsigned default 0;
alter table cats add column summary text;
alter table cats add column keyWorks text;
alter table cats add column introductions text;
alter table cats add column summaryUpdated datetime;
alter table cats add column summaryChecked tinyint(1) unsigned default 1;
alter table cats add column advertiseSummary datetime;

