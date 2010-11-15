alter table main_authors add column mereFirstname varchar(50);
alter table main_authors add index(lastname,mereFirstname);
