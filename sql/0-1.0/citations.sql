create table citations( id int unsigned auto_increment primary key, xml text, volume int, issue varchar(32), issn varchar(100), title varchar(1000), pages varchar(32), source varchar(255), authors varchar(1000), date varchar(16), doi varchar(255), fromeId varchar(11), toeId varchar(11) );
alter table citations add index(xml(255));
alter table citations add index( fromeId );
alter table citations add index( toeId );

