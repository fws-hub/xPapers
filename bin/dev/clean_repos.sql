update oai_repos set sets = null, non_eng_records = 0, fetched_records = 0, saved_records = 0, scanned_at = null; 

delete from main where source_id like 'oai://%';

update oai_repos set error_log = null;

delete from entry_origin;

