insert into users ( id, firstname ) values ( 8, 'HARVESTER' );
alter table users add column offCampusMethod varchar(32);
alter table users add column resolver varchar(255);
update users set offCampusMethod = 'proxy' where proxy is not null;
alter table users drop column offCampusMethod;
alter table users drop column resolver;
alter table users add column rId int unsigned;
alter table users add column locale varchar(2);

insert into users ( id, firstname, confirmed, email, passwd ) values ( 10, 'TESTER', 1, 'test@example.com', 'frJkG8w9TmUptp0xNc9xmQ' ); 
#thdtup
insert into users ( id, firstname, confirmed, email, passwd, admin ) values ( 5, 'ADMIN TESTER', 1, 'admin_test@example.com', 'frJkG8w9TmUptp0xNc9xmQ', 1 ); 
#thdtup

alter table users add column anonymousFollowing tinyint(1);
alter table users add column alertFollowed tinyint(1) default 0;
alter table users change column alertFollowed alertFollowed tinyint(1);
alter table users change column flags flags set('PROXY','AUTO','BANNED','DISABLED','NOFOLLOWERS') DEFAULT NULL
alter table users add column betaTester tinyint(1);
update users set betaTester = 1 where id = 5;
