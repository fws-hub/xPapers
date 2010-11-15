create table locks ( id varchar(64), uId int unsigned, time timestamp );
alter table locks add primary key (id);
