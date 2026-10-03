CREATE TABLE IF NOT EXISTS `player_playtime` (
    `identifier` VARCHAR(64)  NOT NULL,
    `seconds`    INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`identifier`)
);
