alter table main add column serial int unsigned auto_increment unique key;
update main set type='book' where pub_type='book' or pub_type='thesis';
update main set type='article' where isnull(type) and not isnull(pub_type) and not pub_type='unknown';
update main set pub_type='unknown' where isnull(pub_type);
alter table main_authors add column `date` varchar(16);
alter table main_authors change column `date` year varchar(16);
alter table main drop column cachebin;
alter table main add column cacheId int unsigned;
alter table main drop column publishAbstract;
alter table main drop column ed_comment;
alter table main drop column prob_mindy;
alter table main drop column evaluated;
alter table main drop column enriched;
alter table main drop column canon_url;
alter table main drop column possible_cats;
alter table main drop column seen;
alter table main drop column banned;
alter table main drop column in_biblio;
alter table main drop column source_is_unparsed;
alter table main drop column status;
alter table main drop column philosophy;
alter table main drop column handicap;
alter table main drop column misc;
alter table main drop column harvest_id;
alter table main drop column filterField;
alter table main drop column fromArchive;
alter table main drop column areas;
alter table main drop column reviewed_authors;
alter table main drop column reviewed_date;
alter table main drop column reviewed_publisher;
alter table main drop column month;
alter table main drop column firstParent;
alter table main drop column firstParentNumId;
alter table main drop column lockUser;
alter table main drop column lockTime;



