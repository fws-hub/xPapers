alter table cats add column historicalFacetOf int unsigned;
alter table cats add column historicalLeaf int unsigned default 0;
alter table cats add column summary text;
alter table cats add column keyWorks text;
alter table cats add column introductions text;

