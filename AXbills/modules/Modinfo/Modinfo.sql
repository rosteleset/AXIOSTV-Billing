CREATE TABLE IF NOT EXISTS `modinfo_tips` (
  `id`       SMALLINT(4)   UNSIGNED NOT NULL AUTO_INCREMENT,
  `tip`      VARCHAR(512)           NOT NULL DEFAULT '',
  PRIMARY KEY(`id`)
)
  DEFAULT CHARSET = utf8
  COMMENT = 'Modinfo tips';

INSERT IGNORE INTO modinfo_tips (tip) VALUES
('Если вы по ошибке выполнили команду не с правами администратора, то вы можете в следующей строке просто написать "sudo !!".'),
('Если вы по ошибке выполнили команду в виде пути, то вы можете написать "cd !!".'),
('Тот, кто это увидит - пусть будет счастлив :)'),
('При неправильном отображении терминала, стоит использовать команду "reset".'),
('Для оптимизации базы данных, используйте команду "mysqlcheck -o *база данных*".'),
('Чтобы посмотреть историю введённых команд - введите в терминале "history". Можно использовать и в форме "history | grep *команда*".'),
('Команда "cd .." выполняет переход на уровень выше, "cd -" - возврат в предыдущую директорию, а "cd ~" -- возвращает в домашнюю папку пользователя.'),
('Печатая команды в терминале, можно сэкономить время. Не дописывая команду, введите клавишу Tab, и ОС, при условии только одного совпадения, подставит значение автоматически. Если этого не случилось - нажмите Tab снова, и вам покажет все варианты.'),
('Чтобы выполнить последнюю команду снова, используйте "!". Можно использовать с аргументом, в виде последней команды с такой же программой. Например, "!cd".'),
('Чтобы выполнить последнюю команду с аргументом - используйте "!!*аргумент*".'),
('Вы можете использовать команду в фоновом режиме. Например, вы открыли файл в Vim, и хотите переключиться, где-то что-то посмотреть. Используйте сочетание клавиш Ctrl + Z, и вы вернётесь в терминал. Чтобы вернуться к этой "выполненной команде" -- введите "fg".'),
('Чтобы просмотреть список каталогов -- используйте команду ls, с опциями -l - выведет список, -a - покажет скрытые файлы.'),
('Для того, чтобы вывести содержимое файла в консоли -- используйте команду "cat *файл*".'),
('Если вы хотите узнать, в каком каталоге сейчас находитесь -- введите команду "pwd".'),
('Если вы не знаете, что за файл перед вами -- введите команду "file *название файла*"'),
('Для того, чтобы скопировать файл или каталог -- используйте команду "cp".'),
('Для того, чтобы переместить файл или каталог -- используйте команду "mv.'),
('Интересный факт. Перемещение и переименование файла -- одна и та же операция для ОС Linux.'),
('Для того, чтобы удалить файл/каталог - используйте команду "rm". А если папка не пустая - используйте опцию "-r".'),
('Чтобы изменить права доступа к файлу, используйте команду "chmod". Так же существует опция с рекурсией -- "-r". Если файл не желает запуститься как программа -- используйте опцию +X.'),
('Если вы желаете посмотреть, сколько занимает тот или файл/каталог -- используйте команду "du". Также полезно использовать опцию -h, которая позволит вывести размер в человекочитаемом формате.'),
('Чтобы посмотреть дисковое пространство, введите команду "df", и также существует опция -h, которая позволит читать в человекочитаемом формате.'),
('Чтобы посмотреть документацию про той или иной программе - используйте команду "man *название*".');