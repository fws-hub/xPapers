create table plugin_tests ( id int unsigned auto_increment primary key, url varchar(500), plugin varchar(128), expected text, last text );
alter table plugin_tests add column created datetime;
alter table plugin_tests add column lastChecked datetime;
alter table plugin_tests add column lastStatus varchar(10);

