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
dbname = "OBSERVERDB"
user = 'annndrey'
host = 'aldebaran'
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
u'координаты начала', 
u'координаты конца', 
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
'stations.latgradbeg, stations.latminbeg, stations.longradbeg, stations.lonminbeg':u'координаты начала', 
'stations.latgradend, stations.latminend, stations.longradend, stations.lonminend':u'координаты конца', 
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
'squid':u'головоногие', 
'algae':u'водоросли', 
'golotur':u'голотурии', 
'molusk':u'брюхоногие', 
'pelecipoda':u'двустворчатые'}

bio_headers = [u'высота раковины',
u'общий вес',
u'год',
u'вес',
u'длина раковины', 
u'стадия зрелости яичника', 
u'номер особи', 
u'пол', 
u'вес кожно-мускульного мешка', 
u'комментарий', 
u'вес гонады', 
u'стадия развития гонады', 
u'стадия петазмы', 
u'состояние половых отверстий', 
u'повреждения ног', 
u'промысловая длина тела', 
u'стадия теликума', 
u'стернальные шипы', 
u'метка', 
u'цвет гонад', 
u'линочная стадия', 
u'номер страты',
u'вид', 
u'икра', 
u'диаметр тела', 
u'гонадный индекс', 
u'наполнение желудка', 
u'высота клешни', 
u'состояние сперматофоров', 
u'наличие шарика спермы', 
u'стадия зрелости', 
u'судно', 
u'подстадия зрелости', 
u'высота панциря', 
u'вес гонад', 
u'вес тела', 
u'номер станции', 
u'ширина раковины', 
u'наблюдатель', 
u'стадия зрелости', 
u'ширина карапакса', 
u'комментарий', 
u'возраст', 
u'номер рейса', 
u'комментарий', 
u'состояние ампул', 
u'длина карапакса', 
u'комментарий', 
u'заболевание', 
u'вес мускула', 
u'форма сперматофоров', 
u'следы спаривания']

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
'mlength':u'промысловая длина тела', 
'stagetelicum':u'стадия теликума', 
'sternal':u'стернальные шипы', 
'label':u'метка', 
'gonadcolor':u'цвет гонад', 
'moltingst':u'линочная стадия', 
'numstrat':u'номер страты', 
'speciescode':u'вид', 
'eggs':u'икра', 
'bodydiametr':u'диаметр тела', 
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
catch_hide_columns = []

bio_hide_columns = []

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
        QtGui.QMainWindow.__init__(self, parent)
        self.ui = MainWindow()
        self.ui.setupUi(self)
        self.undoStack = QtGui.QUndoStack(self)

        self.conn = psycopg2.connect("dbname='%s' user='%s' host='%s' port=%d  password='%s'" % (dbname, user, host, port, passwd))
        self.cur = self.conn.cursor()
        self.stations = []
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
        #Из TripForm надо брать year, survey_type, survey_number, vessel_code.
        #потом select from stations where year, survey_type, survey_number, vessel_code
        #                  catch
        #                  bio
        
            
        
        #Исходная пустая строка для станций

        #Первоначатьный запрос для получения первичных данных
        

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
        self.ui.catchTableView.setAlternatingRowColors(True)
        self.ui.catchTableView.verticalHeader().setDefaultSectionSize(20)
        self.connect(self.catchselectionModel, QtCore.SIGNAL("currentChanged(QModelIndex, QModelIndex)"), self.appendRow)

        #биоанализы
        self.ui.bioTableView.setModel(TableModel([range(1,len(bio_headers_dict)), bio_headers_dict.values(), bio_headers_dict.keys()], bio_headers_dict.values(), self.undoStack, self.conn, self.statusBar, bio_headers_dict.keys(), self))
        self.bioselectionModel = QtGui.QItemSelectionModel(self.ui.bioTableView.model())
        self.ui.bioTableView.setSelectionModel(self.bioselectionModel)
        self.ui.bioTableView.setSortingEnabled(True)
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
        #оно стоит тут, т.к. иначе оно срабатывает после того, как создаются делегаты
        #и при попытке что-то сделать программа умирает с сообщением о SegmentationFault...
        #self.applyChanges()
        
        #Delegates
        #Делегаты для станций

        #станции
        self.spindelegate0 = SpinBoxDelegate(self.ui.stationsTableView.model())
        self.spindelegate1 = SpinBoxDelegate(self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(0, self.spindelegate0)
        self.ui.stationsTableView.setItemDelegateForColumn(1, self.spindelegate1)
        #delegate = ComboBoxDelegate(parent = self.ui.bioTableView.model())
        #self.ui.bioTableView.setItemDelegateForColumn(0, delegate)

        #координаты - широта и долгота. Широта - 0-90, долгота - 0-180. 
        latRegexp = QtCore.QRegExp(r'1?[0-8]{2}\.[0-5]{1}[0-9]{1}\.[0-9]{2}')
        lonRegexp = QtCore.QRegExp(r'[0-8]{1}[0-9]{1}\.[0-5]{1}[0-9]{1}\.[0-9]{2}')
        coordRegexp = QtCore.QRegExp(r'1?[0-8]{2}\.[0-5]{1}[0-9]{1}\.[0-9]{2}[NS]{1};[0-8]{1}[0-9]{1}\.[0-5]{1}[0-9]{1}\.[0-9]{2}[EW]{1}')
        coordvalidator = QtGui.QRegExpValidator(coordRegexp, self)
        coordBegDelegate = LineEditDelegate(parent = self.ui.stationsTableView.model(), validator = coordvalidator)
        coordEndDelegate = LineEditDelegate(parent = self.ui.stationsTableView.model(), validator = coordvalidator)
        self.ui.stationsTableView.setItemDelegateForColumn(12, coordBegDelegate)
        self.ui.stationsTableView.setItemDelegateForColumn(13, coordEndDelegate)
        
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
        self.ui.stationsTableView.setItemDelegateForColumn(14, cellDelegate)
        #расстояние между ловушками
        trapdistDelegate = IntDelegate([1, 1000, 1], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(15, trapdistDelegate)
        #количество ловушек
        trapnumDelegate = IntDelegate([1, 10000, 1], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(16, trapnumDelegate)
        #кол-во обработанных ловушек
        trapprocessedDelegate = IntDelegate([0, 10000, 1], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(17, trapprocessedDelegate)
        #вес пробы
        sampleWeightDelegate = IntDelegate([0, 10000, 1], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(18, sampleWeightDelegate)
        #давление воздуха min и max - отсюда [http://meteoclub.ru/index.php?action=vthread&topic=922]
        pressDelegate = IntDelegate([880, 1134, 1013], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(19, pressDelegate)
        #температура воздуха
        temperDelegate = IntDelegate([-89, 60, 22], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(20, temperDelegate)
        #скорость ветра
        windSpeedDelegate = IntDelegate([0, 50, 3], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(21, windSpeedDelegate)
        #направление ветра, румбы. Румб - 1/32 окружности
        windDirectDelegate = IntDelegate([1, 32, 17], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(22, windDirectDelegate)
        #волнение моря, баллы 0-9
        seaSurfDelegate = IntDelegate([0, 9, 1], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(23, seaSurfDelegate)
        #температура воды
        seaTempDelegate = IntDelegate([-4, 45, 10], self.ui.stationsTableView.model())  
        self.ui.stationsTableView.setItemDelegateForColumn(24, seaTempDelegate)
        #температура у дна
        bottomTempDelegate = IntDelegate([-6, 45, 4], self.ui.stationsTableView.model())
        self.ui.stationsTableView.setItemDelegateForColumn(25, bottomTempDelegate)
        
        #Делегаты для уловов
        #станция
        catchStDelegate = ComboBoxDelegate(parent = self.ui.catchTableView.model())
        catchStDelegate.values = self.stations
        self.ui.catchTableView.setItemDelegateForColumn(0, catchStDelegate)
        #вид
        speciesDelegate = ComboBoxDelegate(parent = self.ui.catchTableView.model())
        
        

        

        #Потом, в зависимости от вида, прятать те или иные колонки. Отображаться колонки будут для того вида, который в настоящий момент 
        #выбран. Прописано это поведение будет прямо в модели. То же самое придется делать и для станций и для уловов. Поэтому
        #еще раз пишу - надо переделать модель!!! для всех!!!


        #self.connect(self.ui.tripForm.buttonBox, accepted, change_view)
        #change_view -> change stations, change_catch, change_bio
        #
        #self.connect(self.ui.tripForm.surveycomboBox, hide_station_columns)
        #self.connect(self.ui.tripForm.objectComboBox, hide_bio_columns)
        #
        
        #Показ формы настроек рейса и пр.
        self.connect(self.ui.setupaction, QtCore.SIGNAL('triggered()'), self.tripForm.show)
        self.connect(self.spindelegate0, QtCore.SIGNAL('dataAdded'), self.addStation)
        self.connect(self.tripForm.ui.buttonBox, QtCore.SIGNAL('accepted()'), self.applyChanges)
        #self.connect(spindelegate1, QtCore.SIGNAL('dataAdded'), catchDelegate.addValue)
        
        
    #Сокрытие и показ колонок в таблицах. Сделать в зависимости от вида/орудия лова. 
    def test(self):
        print 'OK'

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
            start_coord = '.'.join(map(str, row[12:16]))
            end_coord = '.'.join(map(str, row[16:20]))
            try:
                row[11] = row[11].decode('utf-8')
            except:
                pass
            row[12] = start_coord
            row[13] = end_coord
            del(row[14:20])
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
            data_catch.append(row)
        if len(data_catch) > 0:
            self.ui.catchTableView.model().dbdata = data_catch
        self.ui.catchTableView.model().reset()

        #сокрытие колонок в таблице уловов - ничего скрывать не надо! (вроде бы)

    #Вот тут будем добавлять новую строчку после того, как будет достигнут конец строки
    def appendRow(self, current, prev):
        model = current.model()
        maxrow = len(model.dbdata)
        maxcolumn = len(model.dbdata[0])
        
        if current.row()+1 == maxrow and current.column()+1 == maxcolumn:
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

class FloatDelegate(QtGui.QItemDelegate):
    def __init__(self, val_range, parent = None):
        QtGui.QItemDelegate.__init__(self, parent)
        self.minmax = val_range
    def createEditor(self, parent, option, index):
        editor = QtGui.QDoubleSpinBox(parent)
        editor.setMinimum(self.minmax[0])
        editor.setMaximum(self.minmax[1])
        return editor
    def setEditorData(self, editor, index):
        value = index.model().data(index, QtCore.Qt.EditRole).toFloat()[0]
        if value == 0:
            editor.setValue(self.minmax[2])
        else:
            editor.setValue(value)

    def setModelData(self, editor, model, index):
        value = editor.value()
        model.setData(index, value, QtCore.Qt.EditRole)


class IntDelegate(QtGui.QItemDelegate):
    def __init__(self, val_range, parent = None):
        QtGui.QItemDelegate.__init__(self, parent)
        self.minmax = val_range

    def createEditor(self, parent, option, index):
        editor = QtGui.QSpinBox(parent)
        #if len(self.minmax) > 2:
        #    editor.setValue(self.minmax[2])
        
        editor.setMinimum(self.minmax[0])
        editor.setMaximum(self.minmax[1])
        return editor
    
    def setEditorData(self, editor, index):
        value = index.model().data(index, QtCore.Qt.EditRole).toInt()[0]
        if value == 0:
            editor.setValue(self.minmax[2])
        else:
            editor.setValue(value)
        
    def setModelData(self, editor, model, index):
        value = editor.value()
        model.setData(index, value, QtCore.Qt.EditRole)

class LineEditDelegate(QtGui.QItemDelegate):
    #Этот делегат будет уметь фильтровать ввод
    #валидатор с параметрами будет передаваться
    #при создании экземпляра класса

    def __init__(self, parent = None, validator = None):
        QtGui.QItemDelegate.__init__(self, parent)
        self.validator = validator

    def createEditor(self, parent, option, index):
        editor = QtGui.QLineEdit(parent)
        validator = self.validator
        editor.setValidator(validator)
        return editor

    def setEditorData(self, editor, index):
        value = index.model().data(index, QtCore.Qt.EditRole).toString()
        editor.setText(value)
    
    def setModelData(self, editor, model, index):
        value = editor.text()
        model.setData(index, value, QtCore.Qt.EditRole)

    def updateEditorGeometry(self, editor, option, index):
        editor.setGeometry(option.rect)


class SpinBoxDelegate(QtGui.QItemDelegate):
    #Приятная особенность - этот делегат будет проверять,
    #чтобы каждая следующая станция не имела бы номера,
    #равного предыдущему

    def __init__(self, parent = None):
        QtGui.QItemDelegate.__init__(self, parent)
        self.prev_values = []

    def createEditor(self, parent, option, index):
        editor = QtGui.QSpinBox(parent)
        editor.setMinimum(1)
        editor.setMaximum(1000000)
        return editor

    def setEditorData(self, editor, index):
        value = index.model().data(index, QtCore.Qt.EditRole).toInt()[0]
        for i in index.model().dbdata:
            try:
                val = i[index.column()].toInt()[0]
                self.prev_values.append(val)
            except:
                pass
                        
        if value not in self.prev_values:
            editor.setValue(value)

    def setModelData(self, editor, model, index):
        value = editor.value()
        if value not in self.prev_values:
            model.setData(index, value, QtCore.Qt.EditRole)
            self.emit(QtCore.SIGNAL("dataAdded"), value)

class DateDelegate(QtGui.QItemDelegate):
    def __init__(self, parent = None):
        QtGui.QItemDelegate.__init__(self, parent)
        
    def createEditor(self, parent, option, index):
        editor = QtGui.QDateEdit(parent)
        editor.setDisplayFormat('dd.MM.yyyy')
        return editor
    
    def setEditorData(self, editor, index):
        #Сделать проверку входных значений.
        #если не подходит, то выставлять текущую
        #try:
        value = index.model().data(index, QtCore.Qt.EditRole).toString()#[0]
        #except IndexError:
        #    value = QtCore.QDate.currentDate()
        #print value, QtCore.QDate.fromString(value, 'dd.MM.yyyy')
        try:
            editor.setDate(QtCore.QDate.fromString(value, 'dd.MM.yyyy'))
        except:
            editor.setDate(QtCore.QDate.currentDate())

    def setModelData(self, editor, model, index):
        value = editor.date()
        model.setData(index, u"%02d.%02d.%s" % (value.day(), value.month(), value.year()), QtCore.Qt.EditRole)
        
class TimeDelegate(QtGui.QItemDelegate):
    def __init__(self, parent = None):
        QtGui.QItemDelegate.__init__(self, parent)

    def createEditor(self, parent, option, index):
        editor = QtGui.QTimeEdit(parent)
        editor.setDisplayFormat('hh:mm')
        return editor

    def setEditorData(self, editor, index):
        #try:
        value = index.model().data(index, QtCore.Qt.EditRole).toString()#[0]
        #print value
        #except IndexError:
        #    value = QtCore.QTime.currentTime()
        #try:
        editor.setTime(QtCore.QTime.fromString(value, 'hh:mm'))
        #except:
        #    editor.setTime(QtCore.QTime.currentTime())
            
    def setModelData(self, editor, model, index):
        value = editor.time()
        model.setData(index, u'%02d:%02d' % (value.hour(), value.minute()), QtCore.Qt.EditRole)

class ComboBoxDelegate(QtGui.QItemDelegate):
    def __init__(self, parent = None, validator = None):
        QtGui.QItemDelegate.__init__(self, parent)
        
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
        value = index.model().data(index, QtCore.Qt.EditRole)#.toInt()[0]
        #self.values.insert(0, unicode(value.toString()))
        #comboBox.addItem(value.toString())
        #print unicode(value.toString())
        #print self.values.index(unicode(value.toString()))
        for i in self.values:
            comboBox.addItem(QtCore.QString(unicode(i)))
        comboBox.setCurrentIndex(self.values.index(unicode(value.toString())))
        #comboBox.setItemText(0, unicode(value.toString()))
        

    def setModelData(self, comboBox, model, index):
        value = comboBox.currentText()
        model.setData(index, value, QtCore.Qt.EditRole)
        
    #def updateEditorData(self, comboBox, value):
    #    comboBox.addItem(QtCore.QString(value))
        
    def updateEditorGeometry(self, editor, option, index):
        editor.setGeometry(option.rect)


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

