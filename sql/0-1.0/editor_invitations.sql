create table editor_invitations( id int unsigned auto_increment primary key, uId int, cId int, created timestamp, sent_at datetime );
alter table editor_invitations add index(uId);
alter table editor_invitations add column status char(1);

