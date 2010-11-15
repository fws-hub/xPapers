create table resolvers ( id integer auto_increment primary key,  url varchar(255), weight float, institution integer, foreign key (institution) references insts(id) );
alter table resolvers add index(url);
alter table resolvers drop column institution;
alter table resolvers add column inst_id integer;
alter table resolvers add foreign key (inst_id) references insts(id);
alter table resolvers change column inst_id iId int unsigned;
alter table resolvers change column id id int unsigned;
alter table resolvers change column id id int unsigned auto_increment;

