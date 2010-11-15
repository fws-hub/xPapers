CREATE TRIGGER entry_del AFTER DELETE ON main FOR EACH ROW BEGIN DELETE FROM cats_me WHERE eId = OLD.id; DELETE FROM forums  WHERE eId = OLD.id; DELETE FROM links_m WHERE eId = OLD.id; DELETE FROM main_authors WHERE eId = OLD.id; DELETE FROM relations WHERE eId1 = OLD.id; DELETE FROM relations WHERE eId2 = OLD.id; DELETE FROM entry_origin WHERE entry_id = OLD.id; DELETE FROM diffs WHERE oId = OLD.id AND class = 'xPapers::Entry'; END; 

DROP TRIGGER entry_del;
CREATE TRIGGER entry_del AFTER DELETE ON main FOR EACH ROW BEGIN DELETE FROM cats_me WHERE eId = OLD.id; DELETE FROM forums  WHERE eId = OLD.id; DELETE FROM links_m WHERE eId = OLD.id; DELETE FROM main_authors WHERE eId = OLD.id; DELETE FROM relations WHERE eId1 = OLD.id; DELETE FROM relations WHERE eId2 = OLD.id; DELETE FROM entry_origin WHERE eId = OLD.id; DELETE FROM diffs WHERE oId = OLD.id AND class = 'xPapers::Entry'; END; 

