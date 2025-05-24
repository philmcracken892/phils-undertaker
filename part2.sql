

CREATE TABLE IF NOT EXISTS `phils_bountywagon_inventory` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `animalhash` int(11) NOT NULL,
  `animallabel` varchar(255) NOT NULL,
  `animallooted` tinyint(1) DEFAULT 0,
  `citizenid` varchar(50) NOT NULL,
  `plate` varchar(10) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `plate` (`plate`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

