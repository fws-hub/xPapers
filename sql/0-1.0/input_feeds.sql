create table input_feeds ( id int unsigned auto_increment primary key, name varchar(255), url varchar(255), lastStatus varchar(20), useSince int unsigned, harvested varchar(255), harvested_at timestamp, db_src varchar(10), pass varchar(32) ) default charset utf8;
alter table input_feeds change column harvested harvested varchar(40);
alter table input_feeds add column noSourceOK tinyint(1) default 0;
alter table input_feeds drop column noSourceOK;
alter table input_feeds add column type varchar(16) default 'journal';
