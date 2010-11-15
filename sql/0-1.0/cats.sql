alter table cats add index(uName);
alter table cats drop column cachebin;
alter table cats add column cacheId int unsigned;
