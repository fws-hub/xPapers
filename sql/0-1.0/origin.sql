create table entry_origin ( entry_id varchar(32) primary key, repo_id  integer, set_spec varchar(255), set_name varchar(255) );
alter table entry_origin add column type varchar(128);
CREATE TRIGGER entry_origin_del BEFORE DELETE ON entry_origin FOR EACH ROW BEGIN UPDATE oai_repos SET saved_records = saved_records - 1 WHERE oai_repos.id = OLD.repo_id; END;
CREATE TRIGGER entry_origin_ins AFTER  INSERT ON entry_origin FOR EACH ROW BEGIN UPDATE oai_repos SET saved_records = saved_records + 1 WHERE oai_repos.id = NEW.repo_id; END;
alter table entry_origin add index(repo_id);
alter table entry_origin add index(set_spec);

DROP TRIGGER entry_origin_del;
CREATE TRIGGER entry_origin_del BEFORE DELETE ON entry_origin FOR EACH ROW BEGIN UPDATE oai_repos SET savedRecords = savedRecords - 1 WHERE oai_repos.id = OLD.repo_id; END;
DROP TRIGGER entry_origin_ins;
CREATE TRIGGER entry_origin_ins AFTER  INSERT ON entry_origin FOR EACH ROW BEGIN UPDATE oai_repos SET savedRecords = savedRecords + 1 WHERE oai_repos.id = NEW.repo_id; END;

alter table entry_origin change entry_id eId varchar(32);

