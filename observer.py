#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys, operator

from PyQt4 import QtCore, QtGui

#Импорт форм
#Главное окно
from main_window import Ui_MainWindow as MainWindow
#Форма авторизации
from authoriz import Ui_Dialog as AuthDialog
#Настройка рейса
from trip_setup import Ui_Dialog as TripDialog

#Импорт необходимых библиотек
import psycopg2, psycopg2.extras
from psycopg2.extensions import adapt

#Настройки БД по умолчанию. Потом брать из файла настроек.
dbname = "observ"
user = 'annndrey'
host = 'localhost'
port = 5432
passwd = 'andreygon'

#надо добавить год, судно, номер рейса, наблюдатель в станции и уловы и сделать их нередактируемыми. 

#получение списка колонок для каждой группы видов
#species_columns = select column_name from information_schema.columns where table_name like '%[bio_group]';

objects_dict = {'asteroidea':u'морские звезды',
None:'',
'echinoidea':u'морские ежи',
#'crinoidea':u'морские лилии',
'crab':u'крабы',
'squid':u'головоногие моллюски',
#'algae':u'водоросли',
'krill':u'криль',
#'golotur':u'голотурии',
#'pisces':u'рыбы',
'molusk':u'брюхоногие моллюски',
'krevet':u'креветки',
'pelecipoda':u'двустворчатые моллюски',
'craboid':u'крабоиды',
}

type_survey_dict = {u'траловая':'1',
              u'ловушечная':'2',
              u'водолазная':'3',
              u'комбинированная':'4',
              }


station_headers = [u'станция',
u'№ в судовом журнале', 
u'дата постановки', 
u'время постановки', 
u'дата выборки', 
u'время выборки', 
u'глубина начала', 
u'глубина конца', 
u'скорость траления, узл.',
u'глубина траления',
u'длина ваеров',
u'грунт', 
u'широта начала',
u'долгота начала',
u'широта конца', 
u'долгота конца',
#u'орудие лова', 
u'ячея', 
u'расстояние между ловушками', 
u'число ловушек', 
u'обработано', 
u'Вес пробы',
u'атм. давление, гПа', 
u'Т возд.,°С', 
u'V ветра, м/с', 
u'направление ветра', 
u'волнение', 
u'Т поверхн. воды.,°С', 
u'T воды у дна, °С']

station_headers_dict = {'stations.numstn':u'станция', 
'stations.numjurnalstn':u'№ в судовом журнале', 
'stations.datebegin':u'дата постановки', 
'stations.timebegin':u'время постановки', 
'stations.dateend':u'дата выборки', 
'stations.timeend':u'время выборки', 
'stations.depthbeg':u'глубина начала', 
'stations.depthend':u'глубина конца', 
'stations.vtral':u'скорость траления, узл.',
'stations.depthtral':u'глубина траления',
'stations.wirelength':u'длина ваеров',
'grunt_spr.name':u'грунт', 
'stations.latgradbeg, stations.latminbeg':u'широта начала',
 'stations.longradbeg, stations.lonminbeg':u'долгота начала',
'stations.latgradend, stations.latminend':u'широта конца',
'stations.longradend, stations.lonminend':u'долгота конца', 
#'gearcode':u'орудие лова', 
'stations.cell':u'ячея', 
'stations.trapdist':u'расстояние между ловушками', 
'stations.nlov':u'число ловушек', 
'stations.nlovobr':u'обработано', 
'stations.press':u'атм. давление, гПа', 
'stations.t':u'Т возд.,°С', 
'stations.vwind':u'V ветра, м/с', 
'stations.rwind':u'направление ветра', 
'stations.wave':u'волнение', 
'stations.tsurface':u'Т поверхн. воды.,°С', 
'stations.tbottom':u'T воды у дна, °С',
'stations.samplewght':u'Вес пробы',
}

#это все столбцы станций
#myear
#vesselcode
#numsurvey
# numstn
#typesurvey
# numjurnalstn
# nlov
#gearcode
# vtral
# datebegin
# timebegin
# latgradbeg
# latminbeg
# longradbeg
# lonminbeg
# depthbeg
# dateend
# timeend
# latgradend
# latminend
# longradend
# lonminend
# depthend
# depthtral
# wirelength
# nlovobr
# bottomcode
# press
# t
# vwind
# rwind
# wave
# tsurface
# tbottom
# samplewght
#observnum
# cell
# trapdist
#formcatch
#lcatch
#wcatch
#hcatch
#nentr
#kurs
#observcode
#ngrupspec?
#flagsgrup?

#это уловы
#myear
#vesselcode
#numsurvey
#numstn
#grup
#speciescode
#measure
#catch
#commcatch
#samplewght
#observcode
#comment1
#comment2
#comment3
#catchpromm
#catchnonpromm
#catchf
#weightm
#weightf
#weightj

#вес пробы - в станции

catch_headers = [u'№ станции', 
u'вид', 
u'улов', 
u'комм. улов', 
u'вес пробы', 
u'пром. самцы, шт', 
u'непром. самцы, шт', 
u'самки, шт', 
u'комментарий',]

catch_headers_dict = {'catch.numstn':u'№ станции', 
'species_spr.namerus, species_spr.namelat':u'вид', 
'catch.catch':u'улов', 
'catch.commcatch':u'комм. улов', 
'catch.samplewght':u'вес пробы', 
'catch.catchpromm':u'пром. самцы, шт', 
'catch.catchnonpromm':u'непром. самцы, шт', 
'catch.catchf':u'самки, шт', 
'catch.comment1':u'комментарий',}

bio_groups = [u'криль', u'креветки', 
u'головоногие', 
u'ежи', 
u'крабы', 
u'головоногие', 
u'водоросли', 
u'голотурии', 
u'брюхоногие', 
u'двустворчатые']

bio_groups_dict = {'krill':u'криль', 
'krevet':u'креветки', 
'squid':u'головоногие', 
'echinoidea':u'ежи', 
'crab':u'крабы', 
'craboid':u'крабоиды', 
'algae':u'водоросли', 
'golotur':u'голотурии', 
'molusk':u'брюхоногие', 
'pelecipoda':u'двустворчатые'}

bio_headers = [
#общее для всех
u'номер станции', 
u'номер особи', 
u'вид', 
#крабы и крабоиды
u'ширина карапакса', 
u'длина карапакса', 
u'высота клешни', 
u'линочная стадия', 
u'пол', 
u'стадия зрелости',
u'икра', 
u'вес',
u'повреждения ног', 
u'метка', 
u'заболевание', 
#креветки
u'промысловая длина карапакса',
u'стадия развития гонады', 
u'стернальные шипы', 
#моллюски блюхоногие и двустворки?
u'высота раковины',
u'длина раковины', 
u'ширина раковины', 
u'вес кожно-мускульного мешка', 
u'вес мускула', 
#головоногие
u'возраст', 
u'стадия зрелости яичника', 
u'наполнение желудка', 
u'общий вес',
u'вес тела', 
u'вес гонады', 
#иглокожие
u'диаметр панциря', 
u'высота панциря', 
u'вес гонад', 
u'цвет гонад', 
u'гонадный индекс', 
#криль
u'подстадия зрелости', 
u'стадия петазмы', 
u'стадия теликума', 
u'состояние сперматофоров', 
u'состояние половых отверстий', 
u'наличие шарика спермы', 
u'состояние ампул', 
u'форма сперматофоров', 
u'следы спаривания',
u'комментарий', 
]

bio_headers_dict = {'shellheight':u'высота раковины', 
'bodywght':u'общий вес', 
'myear':u'год', 
'weight':u'вес', 
'shelllength':u'длина раковины', 
'stageovary':u'стадия зрелости яичника', 
'numspec':u'номер особи', 
'sex':u'пол', 
'kmmweight':u'вес кожно-мускульного мешка', 
'comment3':u'комментарий', 
'gonadweight':u'вес гонады', 
'gonad':u'стадия развития гонады', 
'stagepetasma':u'стадия петазмы', 
'condgenapert':u'состояние половых отверстий', 
'leglost':u'повреждения ног', 
'mlength':u'промысловая длина карапакса', 
'stagetelicum':u'стадия теликума', 
'sternal':u'стернальные шипы', 
'label':u'метка', 
'gonadcolor':u'цвет гонад', 
'moltingst':u'линочная стадия', 
'numstrat':u'номер страты', 
'speciescode':u'вид', 
'eggs':u'икра', 
'bodydiametr':u'диаметр панциря', 
'gonadindex':u'гонадный индекс', 
'stomach':u'наполнение желудка', 
'clawhight':u'высота клешни', 
'condspf':u'состояние сперматофоров', 
'spermball':u'наличие шарика спермы', 
'maturstage':u'стадия зрелости', 
'vesselcode':u'судно', 
'substagemat':u'подстадия зрелости', 
'bodyheight':u'высота панциря', 
'gonadwght':u'вес гонад', 
'bodyweight':u'вес тела', 
'numstn':u'номер станции', 
'shellwidth':u'ширина раковины', 
'observcode':u'наблюдатель', 
'stagemat':u'стадия зрелости', 
'wkarapax':u'ширина карапакса', 
'comment4':u'комментарий', 
'age':u'возраст', 
'numsurvey':u'номер рейса', 
'comment1':u'комментарий', 
'condamp':u'состояние ампул', 
'lkarapax':u'длина карапакса', 
'comment2':u'комментарий', 
'illnesscode':u'заболевание', 
'musclewght':u'вес мускула', 
'spfform':u'форма сперматофоров', 
'mating':u'следы спаривания'}

#номера колонок, которые надо скрывать
stations_hide_columns = {
u'траловая':[station_headers.index(u'скорость траления, узл.'), 
        station_headers.index(u'глубина траления'),
        station_headers.index(u'длина ваеров'),
        station_headers.index(u'ячея'),
        ],
u'ловушечная':[station_headers.index(u'расстояние между ловушками'),
       station_headers.index(u'число ловушек'),
       station_headers.index(u'обработано'),
       station_headers.index(u'ячея'),
       ],
u'водолазная':[],
u'комбинированная':[],
}

#в уловах скрывать ничего не надо
catch_hide_columns = {}

bio_hide_columns = {
'krill':[u'подстадия зрелости',
u'стадия петазмы',
u'стадия теликума',
u'состояние сперматофоров',
u'состояние половых отверстий',
u'наличие шарика спермы',
u'состояние ампул',
u'форма сперматофоров',
u'следы спаривания',
],
'krevet':[u'промысловая длина карапакса',
u'длина карапакса',
u'ширина карапакса',
u'стадия развития гонады',
u'стернальные шипы',],
'squid':[u'возраст',
u'стадия зрелости яичника',
u'наполнение желудка',
u'общий вес',
u'вес тела',
u'вес гонады',
],
'echinoidea':[u'диаметр панциря',
u'высота панциря',
u'вес гонад',
u'цвет гонад',
u'гонадный индекс',],
'crab':[u'ширина карапакса',
u'длина карапакса',
u'высота клешни',
u'линочная стадия',
u'пол',
u'стадия зрелости',
u'икра',
u'вес',
u'повреждения ног',
u'метка',
u'заболевание',],
'craboid':[u'ширина карапакса',
u'длина карапакса',
u'высота клешни',
u'линочная стадия',
u'пол',
u'стадия зрелости',
u'икра',
u'вес',
u'повреждения ног',
u'метка',
u'заболевание',],
'algae':[],
u'golotur':[],
'molusk':[u'высота раковины',
u'длина раковины',
u'ширина раковины',
u'вес кожно-мускульного мешка',
u'вес мускула',
],
'pelecipoda':[u'высота раковины',
u'длина раковины',
u'ширина раковины',
u'вес кожно-мускульного мешка',
u'вес мускула',
],
'squid':[u'возраст',
u'стадия зрелости яичника',
u'наполнение желудка',
u'общий вес',
u'вес тела',
u'вес гонады',],
}

column_names_query = """select column_name from information_schema.columns where table_name ilike '%%%s'"""

class TripForm(QtGui.QDialog):
    def __init__(self, parent = None):
        QtGui.QWidget.__init__(self, parent)
        self.ui = TripDialog()
        self.ui.setupUi(self)

class AuthForm(QtGui.QDialog):
    def __init__(self, parent = None):
        QtGui.QWidget.__init__(self, parent)
        self.ui = AuthDialog()
        self.ui.setupUi(self)
        self.ui.lineEdit.setText(dbname)
        self.ui.lineEdit_1.setText(host)
        self.ui.lineEdit_2.setText(str(port))
        self.ui.lineEdit_3.setText(user)
        self.ui.lineEdit_4.setText(passwd)

class MainView(QtGui.QMainWindow):
    
    #Инициализация главного окна
    def __init__(self, dbname, host, post, user, passwd, parent = None):
        super(MainView, self).__init__()
        self.ui = MainWindow()
        self.ui.setupUi(self)
        self.undoStack = QtGui.QUndoStack(self)

        self.conn = psycopg2.connect("dbname='%s' user='%s' host='%s' port=%d  password='%s'" % (dbname, user, host, port, passwd))
        self.cur = self.conn.cursor()
        self.stations = [1, ]
        self.sp_num = 1
        #форма настроек рейса
        self.tripForm = TripForm(self)
        
        #добавление судов в форму настроек рейса
        self.cur.execute('select name, vesselcode from vessel_spr order by name;')
        for i in xrange(self.cur.rowcount):
            vessel = self.cur.fetchone()
            self.tripForm.ui.vesselComboBox.addItem(QtCore.QString(u'%s, %s' % (vessel[0].decode('utf-8'), vessel[1].decode('utf-8'))))
        #добавление групп организмов в форму настроек рейса
        self.cur.execute('select distinct grup from species_spr order by grup asc;')
        for i in xrange(self.cur.rowcount):
            #добавление групп в форму
            try:
                self.tripForm.ui.objectComboBox.addItem(QtCore.QString(objects_dict[self.cur.fetchone()[0]]))
            except KeyError:
                pass

        #станции
        #Исходная пустая строка для станций
        init_list = []
        for i in xrange(len(station_headers)):
            init_list.append('')
        
        self.ui.stationsTableView.setModel(TableModel([init_list, ], station_headers, self.undoStack, self.conn, self.statusBar, station_headers, self))
        self.stationsselectionModel = QtGui.QItemSelectionModel(self.ui.stationsTableView.model())
        self.ui.stationsTableView.setSelectionModel(self.stationsselectionModel)
        self.ui.stationsTableView.resizeColumnsToContents()
        self.ui.stationsTableView.setSortingEnabled(True)
        self.ui.stationsTableView.setAlternatingRowColors(True)
        self.ui.stationsTableView.verticalHeader().setDefaultSectionSize(20)
        self.connect(self.stationsselectionModel, QtCore.SIGNAL("currentChanged(QModelIndex, QModelIndex)"), self.appendRow)

        #уловы
        #Исходная пустая строка для уловов
        init_list = []
        for i in xrange(len(catch_headers)):
            init_list.append('')
        self.ui.catchTableView.setModel(TableModel([init_list, ], catch_headers, self.undoStack, self.conn, self.statusBar, catch_headers, self))
        self.catchselectionModel = QtGui.QItemSelectionModel(self.ui.catchTableView.model())
        self.ui.catchTableView.setSelectionModel(self.catchselectionModel)
        self.ui.catchTableView.setSortingEnabled(True)
        self.ui.catchTableView.resizeColumnsToContents()
        self.ui.catchTableView.setAlternatingRowColors(True)
        self.ui.catchTableView.verticalHeader().setDefaultSectionSize(20)
        self.connect(self.catchselectionModel, QtCore.SIGNAL("currentChanged(QModelIndex, QModelIndex)"), self.appendRow)

        #биоанализы
        init_list = []
        for i in xrange(len(bio_headers)):
            init_list.append('')
        self.ui.bioTableView.setModel(TableModel([init_list, ], bio_headers, self.undoStack, self.conn, self.statusBar, bio_headers, self))
        self.bioselectionModel = QtGui.QItemSelectionModel(self.ui.bioTableView.model())
        self.ui.bioTableView.setSelectionModel(self.bioselectionModel)
        self.ui.bioTableView.setSortingEnabled(True)
        self.ui.bioTableView.resizeColumnsToContents()
        self.ui.bioTableView.setAlternatingRowColors(True)
        self.ui.bioTableView.verticalHeader().setDefaultSectionSize(20)
        self.connect(self.bioselectionModel, QtCore.SIGNAL("currentChanged(QModelIndex, QModelIndex)"), self.appendRow)
        
        #скрытие колонок
        #cols_to_hide = []
        #for i in stations_hide_columns.keys():
        #    if i != unicode(self.tripForm.ui.surveycomboBox.currentText()):
        #        for j in stations_hide_columns[i]:
        #            cols_to_hide.append(j)
        #self.hideColumns(self.ui.stationsTableView, cols_to_hide)
        #применение настроек из формы настройки рейса
        
        

        self.ui.tabWidget.setTabEnabled(1, False)
        self.ui.tabWidget.setTabEnabled(2, False)
        #Delegates
        #Делегаты для станций

        #станции
        self.spindelegate0 = SpinBoxDelegate(self.ui.stationsTableView.model())
        self.spindelegate0.values = self.stations
        self.spindelegate1 = SpinBoxDelegate(self.ui.stationsTableView.model())
        self.spindelegate1.values = self.stations
        self.ui.stationsTableView.setItemDelegateForColumn(0, self.spindelegate0)
        self.ui.stationsTableView.setItemDelegateForColumn(1, self.spindelegate1)
        #delegate = ComboBoxDelegate(parent = self.ui.bioTableView.model())
        #self.ui.bioTableView.setItemDelegateForColumn(0, delegate)

        #координаты - широта и долгота. Широта - 0-90, долгота - 0-180. 
        latRegexp = QtCore.QRegExp(r'[N|S][\ |1]?[0-8]{2}\.[0-5]{1}[0-9]{1}\.[0-9]{2}')
        lonRegexp = QtCore.QRegExp(r'[E|W][0-8]{1}[0-9]{1}\.[0-5]{1}[0-9]{1}\.[0-9]{2}')
        coordRegexp = QtCore.QRegExp(r'1?[0-8]{2}\.[0-5]{1}[0-9]{1}\.[0-9]{2}[NS]{1}:[0-8]{1}[0-9]{1}\.[0-5]{1}[0-9]{1}\.[0-9]{2}[EW]{1}')
        latvalidator = CoordValidator(latRegexp, self)
        lonvalidator = CoordValidator(lonRegexp, self)

        latMask = QtCore.QString("""a0DD.DD.DD;""")
        lonMask = QtCore.QString("""aDD.DD.DD""")
        #с использованием маски ввода - пока не работает ((((
	latBegDelegate = LineEditDelegate(parent = self.ui.stationsTableView.model(), validator = latvalidator)#, mask = latMask)
        lonBegDelegate = LineEditDelegate(parent = self.ui.stationsTableView.model(), validator = lonvalidator)#, mask = lonMask)
        self.ui.stationsTableView.setItemDelegateForColumn(12, latBegDelegate)
        self.ui.stationsTableView.setItemDelegateForColumn(13, lonBegDelegate)
        self.ui.stationsTableView.setItemDelegateForColumn(14, latBegDelegate)
        self.ui.stationsTableView.setItemDelegateForColumn(15, lonBegDelegate)
        #дата начала
        dateBegDelegate = DateDelegate(self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(2, dateBegDelegate)
        #время начала
        timeBegDelegate = TimeDelegate(self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(3, timeBegDelegate)
        #дата окончания
        dateEndDelegate = DateDelegate(self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(4, dateEndDelegate)
        #время окончания
        timeEndDelegate = TimeDelegate(self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(5, timeEndDelegate)
        #глубина начала
        depthBegDelegate = IntDelegate([0, 11022, 0], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(6, depthBegDelegate)
        #глубина конца
        depthEndDelegate = IntDelegate([0, 11022, 0], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(7, depthEndDelegate)
        #скорость траления
        trawlSpeedDelegate = FloatDelegate([0, 15, 2.5], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(8, trawlSpeedDelegate)
        #глубина траления
        trawlDepthDelegate = IntDelegate([0, 11022, 250], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(9, trawlDepthDelegate)
        #длина ваеров
        dragropeLengthDelegate = IntDelegate([0, 10000, 700], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(10, dragropeLengthDelegate)
        #грунт
        self.cur.execute("select name from grunt_spr order by bottomcode desc;")
        bottomDelegate = ComboBoxDelegate(self.ui.stationsTableView.model())
        for i in xrange(self.cur.rowcount):
            bottomDelegate.addValue(unicode(self.cur.fetchone()[0].decode('utf-8')))
        self.ui.stationsTableView.setItemDelegateForColumn(11, bottomDelegate)
        #орудие лова
        #переделать. чтобы было select name from gear_spr where mtype = [int]
        #mtype брать из настроек рейса - тип съемки. 
        #то же самое для списка видов.
        #и в зависимости от типа съемки и вида показывать или прятать те или иные ячейки
        #self.cur.execute("select name from gear_spr order by gearcode asc;")
        #gearDelegate = ComboBoxDelegate(self.ui.stationsTableView.model())
        #for i in xrange(self.cur.rowcount):
        #    gearDelegate.addValue(unicode(self.cur.fetchone()[0].decode('utf-8')))
        #self.ui.stationsTableView.setItemDelegateForColumn(11, gearDelegate)
        
        #ячея
        cellDelegate = IntDelegate([1, 1000, 1], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(16, cellDelegate)
        #расстояние между ловушками
        trapdistDelegate = IntDelegate([1, 1000, 1], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(17, trapdistDelegate)
        #количество ловушек
        trapnumDelegate = IntDelegate([1, 10000, 1], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(18, trapnumDelegate)
        #кол-во обработанных ловушек
        trapprocessedDelegate = IntDelegate([0, 10000, 1], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(19, trapprocessedDelegate)
        #вес пробы
        sampleWeightDelegate = IntDelegate([0, 10000, 1], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(20, sampleWeightDelegate)
        #давление воздуха min и max - отсюда [http://meteoclub.ru/index.php?action=vthread&topic=922]
        pressDelegate = IntDelegate([880, 1134, 1013], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(21, pressDelegate)
        #температура воздуха
        temperDelegate = IntDelegate([-89, 60, 22], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(22, temperDelegate)
        #скорость ветра
        windSpeedDelegate = IntDelegate([0, 50, 3], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(23, windSpeedDelegate)
        #направление ветра, румбы. Румб - 1/32 окружности
        windDirectDelegate = IntDelegate([1, 32, 17], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(24, windDirectDelegate)
        #волнение моря, баллы 0-9
        seaSurfDelegate = IntDelegate([0, 9, 1], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(25, seaSurfDelegate)
        #температура воды
        seaTempDelegate = IntDelegate([-4, 45, 10], self.ui.stationsTableView.model())  
        self.ui.stationsTableView.setItemDelegateForColumn(26, seaTempDelegate)
        #температура у дна
        bottomTempDelegate = IntDelegate([-6, 45, 4], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(27, bottomTempDelegate)
        
        #Делегаты для уловов
        #станция
        self.catchStDelegate = ComboBoxDelegate(parent = self.ui.catchTableView.model())
        self.catchStDelegate.values = self.stations
        self.ui.catchTableView.setItemDelegateForColumn(0, self.catchStDelegate)
        #вид
        #speciesDelegate = ComboBoxDelegate(parent = self.ui.catchTableView.model())
        #self.ui.catchTableView.setItemDelegateForColumn(1, speciesDelegate)
        #улов, вес
        self.commonCatchDelegate = IntDelegate([1, 100000, 1], self.ui.catchTableView.model())
        self.ui.catchTableView.setItemDelegateForColumn(2, self.commonCatchDelegate)
        #коммерческий улов, вес
        self.commCatchDelegate = IntDelegate([1, 100000, 1], self.ui.catchTableView.model())
        self.ui.catchTableView.setItemDelegateForColumn(3, self.commCatchDelegate)
        #вес пробы
        self.sampleWeight = IntDelegate([1, 10000, 1], self.ui.catchTableView.model())
        self.ui.catchTableView.setItemDelegateForColumn(4, self.sampleWeight)
        #кол-во промысловых самцов, посмотреть 
        self.commMales = IntDelegate([1, 100000, 100], self.ui.catchTableView.model())
        self.ui.catchTableView.setItemDelegateForColumn(5, self.commMales)
        #непромысловые самцы, кол-во - то же самое - узнать пределы
        self.nonCommMales = IntDelegate([1, 100000, 100], self.ui.catchTableView.model())
        self.ui.catchTableView.setItemDelegateForColumn(6, self.nonCommMales)
        #самки - кол-во
        self.females = IntDelegate([1, 100000, 100], self.ui.catchTableView.model())
        self.ui.catchTableView.setItemDelegateForColumn(7, self.females)
        

        #биоанализы
        #Потом, в зависимости от вида, прятать те или иные колонки. Отображаться колонки будут для того вида, который в настоящий момент 
        #выбран. Прописано это поведение будет прямо в модели. То же самое придется делать и для станций и для уловов. 
                
        #станции
        self.bioStDelegate = ComboBoxDelegate(parent = self.ui.bioTableView.model())
        self.bioStDelegate.values = self.stations
        self.ui.bioTableView.setItemDelegateForColumn(0, self.bioStDelegate)
        #номер особи
        self.specimenNumDelegate = SpinBoxDelegate(self.ui.bioTableView.model())
        self.specimenNumDelegate.values = self.stations
        #self.specimenNumDelegate
        self.ui.bioTableView.setItemDelegateForColumn(1, self.specimenNumDelegate)
        #вид
        self.speciesBioDelegate = ComboBoxDelegate(parent = self.ui.bioTableView.model())
        self.cur.execute("""select distinct namerus, namelat, grup from species_spr order by grup asc""")
        for i in xrange(self.cur.rowcount):
            try:
                species = self.cur.fetchone()
                self.speciesBioDelegate.addValue(u'%s (%s)' % (species[0].decode('utf-8'), species[1].decode('utf-8')))
            except TypeError:
                pass
        self.ui.bioTableView.setItemDelegateForColumn(2, self.speciesBioDelegate)
        #ширина карапакса
        self.carWidthDelegate = IntDelegate([1, 1000, 90], self.ui.bioTableView.model())
        self.ui.bioTableView.setItemDelegateForColumn(3, self.carWidthDelegate)
        #длина карапакса
        self.carLengthDelegate = IntDelegate([1, 1000, 90], self.ui.bioTableView.model())
        self.ui.bioTableView.setItemDelegateForColumn(4, self.carLengthDelegate)
        #высота клешни
        self.clawHeightDelegate = IntDelegate([1, 100, 10], self.ui.bioTableView.model())
        self.ui.bioTableView.setItemDelegateForColumn(5, self.clawHeightDelegate)
        #линочная стадия - зависит от вида!
        self.moltStDelegate = ComboBoxDelegate(parent = self.ui.bioTableView.model())

        #пол - зависит от вида!
        self.sexDelegate = ComboBoxDelegate(parent = self.ui.bioTableView.model())
        
        #стадия зрелости - зависит от вида
        self.matureStage = ComboBoxDelegate(parent = self.ui.bioTableView.model())

        #стадия зрелости икры
        self.roeStage = ComboBoxDelegate(parent = self.ui.bioTableView.model())

        #вес 
        self.weightDelegate = IntDelegate([1, 100000, 1000], self.ui.bioTableView.model())
        self.ui.bioTableView.setItemDelegateForColumn(10, self.weightDelegate)
        
        #повреждения ног - зависит от вида. Придумать делегат для заполнения
        #self.legDamage = 
        
        #метка - текст
        #self.labelDelegate = 
        
        #заболевание
        self.diseaseDelegate = ComboBoxDelegate(parent = self.ui.bioTableView.model())
        self.cur.execute("select distinct name from illness_spr order by name asc")
        for i in xrange(self.cur.rowcount):
            try:
                disease = self.cur.fetchone()
                self.diseaseDelegate.addValue(disease[0].decode('utf-8'))
            except TypeError:
                pass
        self.ui.bioTableView.setItemDelegateForColumn(13, self.diseaseDelegate)

        #промысловая длина карапакса - для креветок
        self.commercCarLength = IntDelegate([1, 500, 40], self.ui.bioTableView.model())
        self.ui.bioTableView.setItemDelegateForColumn(14, self.commercCarLength)
        
        #стадия развития гонады
        self.gonadeStage = LineEditDelegate(parent = self.ui.bioTableView.model())

        self.ui.bioTableView.setItemDelegateForColumn(15, self.gonadeStage)
        
        #стернальные шипы
        self.sternalSpines = ComboBoxDelegate(parent = self.ui.bioTableView.model())
        

        #self.connect(self.ui.tripForm.buttonBox, accepted, change_view)
        #change_view -> change stations, change_catch, change_bio
        #
        #self.connect(self.ui.tripForm.surveycomboBox, hide_station_columns)
        #self.connect(self.ui.tripForm.objectComboBox, hide_bio_columns)
        #
        self.applyChanges()
        
        #создание действий и клавиатурных сокращений.
        #переключение между табами
        self.connect(self.ui.prev_tab, QtCore.SIGNAL("triggered()"), self.rightTab)
        self.connect(self.ui.next_tab, QtCore.SIGNAL("triggered()"), self.leftTab)

        #Показ формы настроек рейса и пр.
        self.connect(self.ui.setupaction, QtCore.SIGNAL('triggered()'), self.tripForm.show)
        self.connect(self.spindelegate0, QtCore.SIGNAL('dataAdded'), self.addStation)
        self.connect(self.tripForm.ui.buttonBox, QtCore.SIGNAL('accepted()'), self.applyChanges)
        self.connect(self.spindelegate0, QtCore.SIGNAL('dataAdded'), self.showTab)
        #self.connect(self.specimenNumDelegate, QtCore.SIGNAL('dataAdded'), self.addNum)
        #если хотя бы один улов добавлен и не равен 0, то показать биоанализы
        self.connect(self.commonCatchDelegate, QtCore.SIGNAL('dataAdded'), self.showTab)
        self.connect(self.speciesBioDelegate, QtCore.SIGNAL('dataChanged'), self.showBioCols)
        self.connect(self.bioselectionModel, QtCore.SIGNAL("currentChanged(QModelIndex, QModelIndex)"), self.showBioCols)
    #Сокрытие и показ колонок в таблицах. Сделать в зависимости от вида/орудия лова. 

    def showBioCols(self, *args):
        if len(args) == 2:
            index = args[0]
            ind = self.ui.bioTableView.model().createIndex(index.row(), 2)
            species = unicode(self.ui.bioTableView.model().data(ind, QtCore.Qt.EditRole).toString())
        elif len(args) == 1:
            species = unicode(args[0])
        
        if len(species) > 1:
            specimen = unicode(species).split(' (')[0].replace(')', '')

            cols_to_hide = []
            cols_to_show = []
        #узнаем группу, к которой относится вид
            #ищем русское название, иначе получается ошибка из-за 
            #дополнительных скобок, как, например, в Креветка северная (атлантический подвид) (Pandalus borealis eous)
            self.cur.execute(u"""select grup from species_spr where namerus ilike '%%%s%%'""" % specimen)
            group = self.cur.fetchone()[0]
            for i in bio_hide_columns.keys():
                if i != group:
                    for j in bio_hide_columns[i]:
                        cols_to_hide.append(bio_headers.index(j))
                else:
                    for j in bio_hide_columns[i]:
                        cols_to_show.append(bio_headers.index(j))
            self.hideColumns(self.ui.bioTableView, cols_to_hide)
            self.showColumns(self.ui.bioTableView, cols_to_show)

    def rightTab(self):
        tab = self.ui.tabWidget.currentIndex()
        
        if tab > 0 and self.ui.tabWidget.isTabEnabled(tab - 1):
            self.ui.tabWidget.setCurrentIndex(tab - 1)
        elif self.ui.tabWidget.isTabEnabled(self.ui.tabWidget.count() -1):
            self.ui.tabWidget.setCurrentIndex(self.ui.tabWidget.count() -1)
        elif self.ui.tabWidget.isTabEnabled(self.ui.tabWidget.count() -2):
            self.ui.tabWidget.setCurrentIndex(self.ui.tabWidget.count() -2)
    def leftTab(self):
        tab = self.ui.tabWidget.currentIndex()
        
        if tab < 2 and self.ui.tabWidget.isTabEnabled(tab + 1):
            self.ui.tabWidget.setCurrentIndex(tab + 1)
        else:
            self.ui.tabWidget.setCurrentIndex(0)

    def showTab(self, *args):
        
        if len(args) == 0:
            tab=0
            self.ui.tabWidget.setTabEnabled(tab+2, True)
        else:
            tab = self.ui.tabWidget.currentIndex()
            self.ui.tabWidget.setTabEnabled(tab+1, True)

    def test(self, data, prev):
        print type(data)

    def addStation(self, data):
        self.stations.append(data)

    def showColumns(self, table, columns):
        for i in columns:
            table.showColumn(i)

    def hideColumns(self, table, columns):
        for i in columns:
            table.hideColumn(i)

    def applyChanges(self):
        #функция применяет изменения, внесенные в 
        #форму настроек рейса

        year = self.tripForm.ui.yearDateEdit.date().year()
        #print year
        vesselcode = unicode(self.tripForm.ui.vesselComboBox.currentText()).split(u', ')[-1]
        #print vesselcode
        numsurvey = self.tripForm.ui.tripSpinBox.value()
        #print numsurvey
        typesurvey = type_survey_dict[unicode(self.tripForm.ui.surveycomboBox.currentText())]
        
        #пошла обработка таблицы станций
        select_query = []
        for i in station_headers:
            select_query.append(station_headers_dict.keys()[station_headers_dict.values().index(i)])

        query =  u'select ' + u', '.join(select_query) + ' from stations, grunt_spr ' + """ where myear = %s and vesselcode = '%s' and numsurvey = %s and typesurvey = %s and stations.bottomcode = grunt_spr.bottomcode""" % (year, vesselcode, numsurvey, typesurvey)
        #print query
        
        self.cur.execute(query)
        data = []
        for row in self.cur.fetchall():
            
            row = list(row)
            #исправление кординат
            start_coord_lat = '%s%02d.%02.2f' % (('N' if row[12] > 0 else 'S'), abs(row[12]), row[13])
            start_coord_lon = '%s%03d.%02.2f' % (('E' if row[14] > 0 else 'W'), abs(row[14]), row[15])
            end_coord_lat = '%s%02d.%02.2f' % (('N' if row[16] > 0 else 'S'), abs(row[16]), row[17])
            end_coord_lon = '%s%03d.%02.2f' % (('E' if row[18] > 0 else 'W'), abs(row[18]), row[19])
            
            try:
                row[11] = row[11].decode('utf-8')
            except:
                pass

            row[12] = start_coord_lat
            row[13] = start_coord_lon
            row[14] = end_coord_lat
            row[15] = end_coord_lon
            del(row[16:20])
            #добавление вытянутых данных в список имеющихся станций
            self.spindelegate0.addPrev(row[0])
            data.append(row)
        #вывод сообщения на статус-бар
        self.statusBar().showMessage(u'%s год, %s, %s съемка, %s' % (year, unicode(self.tripForm.ui.vesselComboBox.currentText()).split(u', ')[0], unicode(self.tripForm.ui.surveycomboBox.currentText()), unicode(self.tripForm.ui.objectComboBox.currentText())))
        #добавление данных к модели станций
        if len(data) > 0:
            self.ui.stationsTableView.model().dbdata = data
        
            self.ui.stationsTableView.model().reset()

        #скрытие и показ ячеек
        cols_to_hide = []
        cols_to_show = []
        for i in stations_hide_columns.keys():
            if i != unicode(self.tripForm.ui.surveycomboBox.currentText()):
                for j in stations_hide_columns[i]:
                    cols_to_hide.append(j)
            else:
                for j in stations_hide_columns[i]:
                    cols_to_show.append(j)
        self.hideColumns(self.ui.stationsTableView, cols_to_hide)
        self.showColumns(self.ui.stationsTableView, cols_to_show)

        #добавление/изменение делегата для колонки видов
        speciesDelegate = ComboBoxDelegate(parent = self.ui.catchTableView.model())
        sp_obj = unicode(self.tripForm.ui.objectComboBox.currentText())
        sp_obj = objects_dict.keys()[objects_dict.values().index(sp_obj)]

        
        self.cur.execute("""select distinct namerus, namelat from species_spr where grup = '%s' order by namerus asc""" % sp_obj)
        for i in xrange(self.cur.rowcount):
            
            try:
                #print unicode(self.cur.fetchone()[0].decode('utf-8'))
                species = self.cur.fetchone()
                speciesDelegate.addValue(u'%s (%s)' % (species[0].decode('utf-8'), species[1].decode('utf-8')))
                
            except TypeError:
                pass
            #speciesDelegate.addValue(u'')
        self.ui.catchTableView.setItemDelegateForColumn(1, speciesDelegate)

        #пошла обработка таблицы уловов
        #speciescode = 
        select_query_catch = []
        for i in catch_headers:
            select_query_catch.append(catch_headers_dict.keys()[catch_headers_dict.values().index(i)])
        #print select_query_catch
        query_catch = u'select ' + u', '.join(select_query_catch) + ' from catch, species_spr ' + """ where myear = %s and vesselcode = '%s' and numsurvey = %s and catch.speciescode = species_spr.speciescode and catch.grup = '%s'""" % (year, vesselcode, numsurvey, sp_obj)
        #print query_catch
        self.cur.execute(query_catch)
        data_catch = []
        
        for row in self.cur.fetchall():
            #print row
            row = list(row)
            row[1] = u'%s (%s)' % (row[1].decode('utf-8'), row[2].decode('utf-8'))
            del(row[2])
            #print row[2]
            self.commonCatchDelegate.dataAdded(row[1])            
            data_catch.append(row)


        if len(data_catch) > 0:
            self.ui.catchTableView.model().dbdata = data_catch
        self.ui.catchTableView.model().reset()

        #отображение биоанализов.
        #тут все не столь очевидно, как в случае с предыдущими таблицами.
        #необходимо выбирать из нескольких таблиц данные для одного года, судна, рейса и наблюдателя
        #идея такая - вначале выводим все для главной группы, указанной в настройках, а потом - для всего остального.
        #или как-то так
        data_bio = []
        #м.б. попробовать сделать union?
        #выбрать столбцы[группа] из bioanalis_группа where год, судно, рейс, наблюдатель равны нашим настройкам
        for i in bio_hide_columns.keys():
            rows = []
            for j in bio_hide_columns[i]:
                rows.append(bio_headers_dict.keys()[bio_headers_dict.values().index(j)])
            print i, ', '.join(rows)
            
    #Вот тут будем добавлять новую строчку после того, как будет достигнут конец строки
    def appendRow(self, current, prev):
        model = current.model()
        maxrow = len(model.dbdata)
        maxcolumn = len(model.dbdata[0])
        
        if current.row()+1 == maxrow and current.column()+1 == maxcolumn:
            #хорошая проверка. надо оставить, чтобы неповадно было создавать новые
            #строки, не заполнив старых
            #if model.dbdata[current.row()][0] != '':
            model.insertRow(current.row()+1, current)
            
            #print 'row', current.row(), prev.row(), maxrow
            #print 'column', current.column(), prev.column(), maxcolumn
        else:
            pass#print current.column()
    

class TableModel(QtCore.QAbstractTableModel):
    def __init__(self, datain, headerdata, undostack, conn, statusbar, columns, parent=None, *args):
        QtCore.QAbstractTableModel.__init__(self, parent, *args)
        self.cur = conn.cursor()
        self.statusbar = statusbar
        self.undostack = undostack
        self.dbdata = datain
        self.header = headerdata
        self.columns = columns
        
    def insertRow(self, row, index, parent=QtCore.QModelIndex()):
        new_row = []
        for i in xrange(len(self.dbdata[0])):
            new_row.append("")
        self.beginInsertRows(parent, row, row)
        
        self.dbdata.insert(row, new_row)
        self.endInsertRows()
        return True

    def rowCount(self, parent):
        #кол-во строк
        return len(self.dbdata)

    def columnCount(self, parent):
        #кол-во колонок
        if len(self.dbdata) < 1:
            return 0
        else:
            return len(self.dbdata[0])
   
    def get_value(self, index):
        i = index.row()
        j = index.column()
        try:
            return self.dbdata[i][j]#.decode("utf-8")
        except AttributeError:
            return self.dbdata[i][j]

    def data(self, index, role):
        if not index.isValid():
            return QtCore.QVariant()
        value = self.get_value(index)

        if role == QtCore.Qt.DisplayRole or role == QtCore.Qt.EditRole:
            return QtCore.QVariant(value)
        elif role == QtCore.Qt.TextAlignmentRole:
                return QtCore.QVariant(QtCore.Qt.AlignCenter)
        return QtCore.QVariant()

        if isinstance(self.dbdata[index.row()][index.column()], str):
            return QtCore.QVariant(self.dbdata[index.row()][index.column()].decode("utf-8"))
        else:
            return QtCore.QVariant(self.dbdata[index.row()][index.column()])

    def headerData(self, col, orientation, role):
        ## тут задаются заголовки
        if orientation == QtCore.Qt.Horizontal and role == QtCore.Qt.DisplayRole:

            #Для исправления ошибки при убирании столбца индекса релевантности
            #при переходе от полнотекстового поиска к сложному при отображении всех столбцов
            try:
                return QtCore.QVariant(self.header[col])
            except IndexError:
                return QtCore.QVariant(self.header[col-1])

    def sort(self, Ncol, order):

        self.emit(QtCore.SIGNAL("layoutAboutToBeChanged()"))
        self.dbdata = sorted(self.dbdata, key=operator.itemgetter(Ncol))
        if order == QtCore.Qt.DescendingOrder:
            self.dbdata.reverse()
        self.emit(QtCore.SIGNAL("layoutChanged()"))


    def setData(self, index, value, role):
        if index.isValid() and role == QtCore.Qt.EditRole:

            val = QtCore.QVariant(self.get_value(index))

            command = EditCommand(self, index.row(), index.column(), self.columns, val, QtCore.QVariant(value), self.cur, 'Edition of a single cell')
            self.undostack.push(command)

            return True
        else:
            return False

    #установка флагов для того, чтобы ячейка становилась редактируемой
    def flags(self, index):
        if not index.isValid():
            return QtCore.Qt.ItemIsEnabled

        return QtCore.Qt.ItemIsEnabled | QtCore.Qt.ItemIsSelectable | QtCore.Qt.ItemIsEditable

class FloatDelegate(QtGui.QStyledItemDelegate):
    def __init__(self, val_range, parent = None):
        QtGui.QStyledItemDelegate.__init__(self, parent)
        self.minmax = val_range
    def createEditor(self, parent, option, index):
        editor = QtGui.QDoubleSpinBox(parent)
        editor.setMinimum(self.minmax[0])
        editor.setMaximum(self.minmax[1])
        return editor
    def setEditorData(self, editor, index):
        model =index.model()
        ind = model.createIndex(index.row(), index.column())
        value =model.data(ind, QtCore.Qt.EditRole).toFloat()[0]
        
        if value == 0:
            editor.setValue(self.minmax[2])
        else:
            editor.setValue(value)

    def setModelData(self, editor, model, index):
        value = editor.value()
        model.setData(index, value, QtCore.Qt.EditRole)


class IntDelegate(QtGui.QStyledItemDelegate):
    def __init__(self, val_range, parent):
        QtGui.QStyledItemDelegate.__init__(self, parent)
        self.minmax = val_range
        self.parent = parent

    def createEditor(self, parent, option, index):
        self.parent = parent
        editor = QtGui.QSpinBox(parent)
        #if len(self.minmax) > 2:
        #    editor.setValue(self.minmax[2])
        
        editor.setMinimum(self.minmax[0])
        editor.setMaximum(self.minmax[1])
        return editor
    
    def setEditorData(self, editor, index):
        model = index.model()
        ind = model.createIndex(index.row(), index.column())
        value = model.data(ind, QtCore.Qt.EditRole).toInt()[0]
        if value == 0:
            editor.setValue(self.minmax[2])
        else:
            editor.setValue(value)
            
    def dataAdded(self, value):
        self.emit(QtCore.SIGNAL("dataAdded"))

    def setModelData(self, editor, model, index):
        value = editor.value()
        model.setData(index, value, QtCore.Qt.EditRole)
        self.emit(QtCore.SIGNAL("dataAdded"), value)

class LineEditDelegate(QtGui.QStyledItemDelegate):
    #Этот делегат будет уметь фильтровать ввод
    #валидатор с параметрами будет передаваться
    #при создании экземпляра класса

    def __init__(self, parent = None, validator = None, mask = None):
        QtGui.QStyledItemDelegate.__init__(self, parent)
        self.validator = validator
        self.mask = mask

    def createEditor(self, parent, option, index):
        editor = QtGui.QLineEdit(parent)
        validator = self.validator

        if self.mask is not None:
            editor.setInputMask(self.mask)

        editor.setValidator(validator)
        return editor

    def setEditorData(self, editor, index):
        model = index.model()
        ind = model.createIndex(index.row(), index.column())
        value = model.data(ind, QtCore.Qt.EditRole).toString()
        
        editor.setText(value)
    
    def setModelData(self, editor, model, index):
        value = editor.text()
        model.setData(index, value, QtCore.Qt.EditRole)

    #def updateEditorGeometry(self, editor, option, index):
    #    editor.setGeometry(option.rect)


class SpinBoxDelegate(QtGui.QStyledItemDelegate):
    #Приятная особенность - этот делегат будет проверять,
    #чтобы каждая следующая станция не имела бы номера,
    #равного предыдущему

    def __init__(self, parent = None):
        QtGui.QStyledItemDelegate.__init__(self, parent)
        self.prev_values = []
        self.values = [1, ]

    def addPrev(self, value):
        self.prev_values.append(value)
        self.emit(QtCore.SIGNAL("dataAdded"), value)

    def createEditor(self, parent, option, index):
        editor = QtGui.QSpinBox(parent)
        editor.setMinimum(1)
        editor.setMaximum(1000000)
        return editor

    def setEditorData(self, editor, index):
        model = index.model()
        ind = model.createIndex(index.row(), index.column())
        
        value = model.data(ind, QtCore.Qt.EditRole).toInt()[0]
        for i in model.dbdata:
            try:
                val = i[ind.column()].toInt()[0]
                self.prev_values.append(val)
            except:
                pass
                        
        if value not in self.prev_values:
            editor.setValue(value)
        else:
            editor.setValue(max(self.values) + 1)

    def setModelData(self, editor, model, index):
        value = editor.value()
        if value not in self.prev_values:
            model.setData(index, value, QtCore.Qt.EditRole)
            self.emit(QtCore.SIGNAL("dataAdded"), value)

class DateDelegate(QtGui.QStyledItemDelegate):
    def __init__(self, parent = None):
        QtGui.QStyledItemDelegate.__init__(self, parent)
        
    def createEditor(self, parent, option, index):
        editor = QtGui.QDateEdit(parent)
        editor.setDisplayFormat('dd.MM.yyyy')
        return editor
    
    def setEditorData(self, editor, index):
        #Сделать проверку входных значений.
        #если не подходит, то выставлять текущую
        #try:
        model = index.model()
        ind = model.createIndex(index.row(), index.column())
        
        value = model.data(ind, QtCore.Qt.EditRole).toString()#[0]
        if str(value) != '':
        #except IndexError:
            editor.setDate(QtCore.QDate.fromString(value, 'dd.MM.yyyy'))
        #print value, QtCore.QDate.fromString(value, 'dd.MM.yyyy')
        else:
            editor.setDate(QtCore.QDate.currentDate())

    def setModelData(self, editor, model, index):
        value = editor.date()
        model.setData(index, u"%02d.%02d.%s" % (value.day(), value.month(), value.year()), QtCore.Qt.EditRole)
        
class TimeDelegate(QtGui.QStyledItemDelegate):
    def __init__(self, parent = None):
        QtGui.QStyledItemDelegate.__init__(self, parent)

    def createEditor(self, parent, option, index):
        editor = QtGui.QTimeEdit(parent)
        editor.setDisplayFormat('hh:mm')
        return editor

    def setEditorData(self, editor, index):
        model = index.model()
        ind = model.createIndex(index.row(), index.column())
        #try:
        value = model.data(ind, QtCore.Qt.EditRole).toString()#[0]
        #print value
        #except IndexError:
        if str(value) != '':
        #if value == u'00:00':
            editor.setTime(QtCore.QTime.fromString(value, 'hh:mm'))
            
        else:
            value = QtCore.QTime.currentTime()
            
            editor.setTime(value)

                        
    def setModelData(self, editor, model, index):
        value = editor.time()
        model.setData(index, u'%02d:%02d' % (value.hour(), value.minute()), QtCore.Qt.EditRole)

class ComboBoxDelegate(QtGui.QStyledItemDelegate):
    def __init__(self, parent = None, validator = None):
        QtGui.QStyledItemDelegate.__init__(self, parent)
        
        self.validator = validator
        self.values = []
        
    def createEditor(self, parent, option, index):
        validator = self.validator
        comboBox = QtGui.QComboBox(parent)
        comboBox.setValidator(validator)
        return comboBox

    def addValue(self, value):
        self.values.append(value)

    def setEditorData(self, comboBox, index):
        model = index.model()
        ind = model.createIndex(index.row(), index.column())
        value = model.data(ind, QtCore.Qt.EditRole)#.toInt()[0]
        #self.values.insert(0, unicode(value.toString()))
        #comboBox.addItem(value.toString())

        #print unicode(value.toString())
        #print self.values.index(unicode(value.toString()))
        for i in self.values:
            comboBox.addItem(QtCore.QString(unicode(i)))
        try:
            comboBox.setCurrentIndex(self.values.index(unicode(value.toString())))
        except ValueError:
            comboBox.setCurrentIndex(0)
        #comboBox.setItemText(0, unicode(value.toString()))
        

    def setModelData(self, comboBox, model, index):
        value = comboBox.currentText()
        model.setData(index, value, QtCore.Qt.EditRole)
        self.emit(QtCore.SIGNAL('dataChanged'), value)
    #вот корень зла! а вот и нет!
    def updateEditorData(self, comboBox, value):
        comboBox.addItem(QtCore.QString(value))
        
    def updateEditorGeometry(self, editor, option, index):
        editor.setGeometry(option.rect)


class CoordValidator(QtGui.QRegExpValidator):
	#наследуем валидатор, чтобы исправлять значения координат	
	def __init__(self, regexp, parent = None):
	    QtGui.QRegExpValidator.__init__(self, regexp, parent)
            self.regexp = regexp

	def fixup(self, inp):
            inp.replace('-', 'S')
            
        #def validate(self, inp, pos):
        #    print inp, pos, self.regexp.indexIn(inp)
        #    if self.regexp.indexIn(inp) == -1:
        #        #if inp.length() > 8:
        #        #    inp.replace(' ', '')
        #        #    return (QtGui.QValidator.Intermediate, pos)
        #        return (QtGui.QValidator.Intermediate, pos)
        #    return (QtGui.QValidator.Acceptable, pos)
        
class EditCommand(QtGui.QUndoCommand):
    def __init__(self, tablemodel, row, column, columns, prev_value, value, cursor, description):
        super(EditCommand, self).__init__(description)
        self.model = tablemodel
        self.row = row
        self.column = column
        self.columns = columns
        self.prev_value = prev_value
        self.value = value
        self.dbdata = self.model.dbdata
        self.cur = cursor

    def redo(self):
        index = self.model.index(self.row, self.column)
        self.dbdata[index.row()][index.column()] = self.value
        self.model.emit(QtCore.SIGNAL("dataChanged(QModelIndex, QModelIndex)"), index, index)

    def undo(self):
        index = self.model.index(self.row, self.column)
        self.model.dbdata[index.row()][index.column()] = self.prev_value
        self.model.emit(QtCore.SIGNAL("dataChanged(QModelIndex, QModelIndex)"), index, index)



def main():
    app = QtGui.QApplication(sys.argv)
    app.setStyle('cleanlooks')
    translator = QtCore.QTranslator(app)
    translator.load("qt_ru.qm")
    app.installTranslator(translator)
    auth_form = AuthForm()
    auth_form.show()

    #window=MainView()
    #window.setWindowTitle(u'База данных')

    def main_window():
        dbname = auth_form.ui.lineEdit.text()
        host = auth_form.ui.lineEdit_1.text()
        port = int(auth_form.ui.lineEdit_2.text())
        user = auth_form.ui.lineEdit_3.text()
        passwd = auth_form.ui.lineEdit_4.text()
        #try:
        window = MainView(dbname, host, port, user, passwd)
        window.setWindowTitle(u'База данных')
        window.show()
        #except:
        #    auth_form.show()

    QtCore.QObject.connect(auth_form.ui.buttonBox, QtCore.SIGNAL("accepted()"), main_window)
    #QtCore.QObject.connect(auth_form.ui, QtCore.SIGNAL('loginData'), main_window)

    sys.exit(app.exec_())




if __name__ == "__main__":
    main()

