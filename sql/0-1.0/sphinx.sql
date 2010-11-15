CREATE TABLE `sphinx_main` ( `id` int(10) unsigned NOT NULL, `weight` int(11) NOT NULL, `query` varchar(3072) NOT NULL, `true_id` varchar(15) DEFAULT NULL, KEY `query` (`query`)) ENGINE=SPHINX DEFAULT CHARSET=latin1 CONNECTION='sphinx://localhost:9312/main_idx,main_idx_stemmed'
CREATE TABLE `sphinx_forums` ( `id` int(10) unsigned NOT NULL, `weight` int(11) NOT NULL, `query` varchar(3072) NOT NULL, KEY `query` (`query`)) ENGINE=SPHINX DEFAULT CHARSET=latin1 CONNECTION='sphinx://localhost:9312/forums_idx,forums_idx_stemmed'
alter table sphinx_forums add column _sph_count int unsigned;
alter table sphinx_main add column _sph_count int unsigned;
alter table sphinx_forums add column _sph_groupby int unsigned;
alter table sphinx_main add column _sph_groupby int unsigned;
