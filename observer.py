#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys, operator

from PyQt4 import QtCore, QtGui

#Импорт форм
#Главное окно
from main_window import Ui_MainWindow as MainWindow
#Форма авторизации
from authoriz import Ui_Dialog as AuthDialog

#Импорт необходимых библиотек
import psycopg2, psycopg2.extras
from psycopg2.extensions import adapt


#Настройки БД по умолчанию. Потом брать из файла настроек.
dbname = "OBSERVERDB"
user = 'annndrey'
host = 'localhost'
port = 5432
passwd = 'andreygon'

#надо добавить год, судно, номер рейса, наблюдатель в станции и уловы и сделать их нередактируемыми. 

station_headers = [u'станция', u'№ в судовом журнале', u'дата постановки', u'время постановки', u'дата выборки', u'время выборки', u'глубина начала', u'глубина конца', u'грунт', u'координаты начала', u'координаты конца', u'глубина начала', u'глубина конца', u'орудие лова', u'вид наживки', u'ячея', u'расстояние между ловушками', u'число ловушек', u'обработано', u'атм. давление, МПа', u'Т возд.,°С', u'V ветра, м/с', u'направление ветра', u'волнение', u'Т воды.,°С']

station_headers_dict = {'station_number':u'станция', 'journ_station':u'№ в судовом журнале', 'begdate':u'дата постановки', 'begtime':u'время постановки', 'enddate':u'дата выборки', 'enttime':u'время выборки', 'begdepth':u'глубина начала', 'enddepth':u'глубина конца', 'bottomcode':u'грунт', 'beglatgrad beglatmin beglonggrad beglongmin':u'координаты начала', 'endlatgrad endlatmin endlonggrad endlongmin':u'координаты конца', 'begdepth':u'глубина начала', 'enddepth':u'глубина конца', 'gearcode':u'орудие лова', '???':u'вид наживки', '????':u'ячея', 'trapdist':u'расстояние между ловушками', 'nlov':u'число ловушек', '?????':u'обработано', 'pressure':u'атм. давление, МПа', 'surfacetemp':u'Т возд.,°С', 'windspeed':u'V ветра, м/с', 'winddirection':u'направление ветра', 'wave':u'волнение', 'temp':u'Т воды.,°С'}

#вес пробы - в станции

catch_headers = [u'№ станции', u'вид', u'улов', u'комм. улов', u'вес пробы', u'пром. самцы, шт', u'непром. самцы, шт', u'самки, шт', u'комментарий',]

catch_headers_dict = {'station_number':u'№ станции', 'species_code':u'вид', 'catch':u'улов', 'commercial_catch':u'комм. улов', 'sampleweigth':u'вес пробы', 'catch_pieces':u'пром. самцы, шт', 'noncommercial_catch':u'непром. самцы, шт', 'catch_females':u'самки, шт', 'comment1':u'комментарий',}

bio_groups = [u'криль', u'креветки', u'головоногие', u'ежи', u'крабы', u'головоногие', u'водоросли', u'голотурии', u'брюхоногие', u'двустворчатые']

bio_groups_dict = {'krill':u'криль', 'krevet':u'креветки', 'squid':u'головоногие', 'echinoidea':u'ежи', 'crab':u'крабы', 'squid':u'головоногие', 'algae':u'водоросли', 'golotur':u'голотурии', 'molusk':u'брюхоногие', 'pelecipoda':u'двустворчатые'}


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

bio_headers_dict = {'shellheight':u'высота раковины', 'bodywght':u'общий вес', 'myear':u'год', 'weight':u'вес', 'shelllength':u'длина раковины', 'stageovary':u'стадия зрелости яичника', 'numspec':u'номер особи', 'sex':u'пол', 'kmmweight':u'вес кожно-мускульного мешка', 'comment3':u'комментарий', 'gonadweight':u'вес гонады', 'gonad':u'стадия развития гонады', 'stagepetasma':u'стадия петазмы', 'condgenapert':u'состояние половых отверстий', 'leglost':u'повреждения ног', 'mlength':u'промысловая длина тела', 'stagetelicum':u'стадия теликума', 'sternal':u'стернальные шипы', 'label':u'метка', 'gonadcolor':u'цвет гонад', 'moltingst':u'линочная стадия', 'numstrat':u'номер страты', 'speciescode':u'вид', 'eggs':u'икра', 'bodydiametr':u'диаметр тела', 'gonadindex':u'гонадный индекс', 'stomach':u'наполнение желудка', 'clawhight':u'высота клешни', 'condspf':u'состояние сперматофоров', 'spermball':u'наличие шарика спермы', 'maturstage':u'стадия зрелости', 'vesselcode':u'судно', 'substagemat':u'подстадия зрелости', 'bodyheight':u'высота панциря', 'gonadwght':u'вес гонад', 'bodyweight':u'вес тела', 'numstn':u'номер станции', 'shellwidth':u'ширина раковины', 'observcode':u'наблюдатель', 'stagemat':u'стадия зрелости', 'wkarapax':u'ширина карапакса', 'comment4':u'комментарий', 'age':u'возраст', 'numsurvey':u'номер рейса', 'comment1':u'комментарий', 'condamp':u'состояние ампул', 'lkarapax':u'длина карапакса', 'comment2':u'комментарий', 'illnesscode':u'заболевание', 'musclewght':u'вес мускула', 'spfform':u'форма сперматофоров', 'mating':u'следы спаривания'}



column_names_query = """select column_name from information_schema.columns where table_name ilike '%%%s'"""


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

        
        self.cur.execute(column_names_query % 'catch')
        
        for i in self.cur.fetchall():
            print i[0]
        

        #пока так...
        #станции
        self.ui.stationsTableView.setModel(TableModel([range(1,len(station_headers_dict)), station_headers_dict.keys(), station_headers], station_headers, self.undoStack, self.conn, self.statusBar, station_headers_dict.keys(), self))

        #for i in station_headers_dict.values():
        #    print i
        self.stationsselectionModel = QtGui.QItemSelectionModel(self.ui.stationsTableView.model())
        self.ui.stationsTableView.setSelectionModel(self.stationsselectionModel)
        self.connect(self.stationsselectionModel, QtCore.SIGNAL("currentChanged(QModelIndex, QModelIndex)"), self.appendRow)
        

        #уловы
        self.ui.catchTableView.setModel(TableModel([range(1,len(catch_headers_dict)), catch_headers_dict.values(), catch_headers_dict.keys()], catch_headers_dict.values(), self.undoStack, self.conn, self.statusBar, catch_headers_dict.keys(), self))
        self.catchselectionModel = QtGui.QItemSelectionModel(self.ui.catchTableView.model())
        self.ui.catchTableView.setSelectionModel(self.catchselectionModel)
        self.connect(self.catchselectionModel, QtCore.SIGNAL("currentChanged(QModelIndex, QModelIndex)"), self.appendRow)


        #биоанализы
        self.ui.bioTableView.setModel(TableModel([range(1,len(bio_headers_dict)), bio_headers_dict.values(), bio_headers_dict.keys()], bio_headers_dict.values(), self.undoStack, self.conn, self.statusBar, bio_headers_dict.keys(), self))
        self.bioselectionModel = QtGui.QItemSelectionModel(self.ui.bioTableView.model())
        self.ui.bioTableView.setSelectionModel(self.bioselectionModel)
        self.connect(self.bioselectionModel, QtCore.SIGNAL("currentChanged(QModelIndex, QModelIndex)"), self.appendRow)

        #Delegate работает
        delegate = ComboBoxDelegate(self.ui.bioTableView.model())
        self.ui.bioTableView.setItemDelegateForColumn(0,delegate)

        #Тут насоздавать делегатов на всё. В делегат написать метод получения значений для ComboBox 
        #или передавать эти значения при создании экземпляра класса


        #Потом, в зависимости от вида, прятать те или иные колонки. Отображаться колонки будут для того вида, который в настоящий момент 
        #выбран. Прописано это поведение будет прямо в модели. То же самое придется делать и для станций и для уловов. Поэтому
        #еще раз пишу - надо переделать модель!!! для всех!!!
        

    #Сокрытие и показ колонок в таблицах. Сделать в зависимости от вида/орудия лова. 

    def showColumns(self, table, columns):
        for i in columns:
            table.showColumn(i)

    def hideColumns(self, table, columns):
        for i in columns:
            table.hideColumn(i)


    #Вот тут будем добавлять новую строчку после того, как будет достигнут конец строки
    def appendRow(self, current, prev):
        model = current.model()
        maxrow = len(model.dbdata)
        maxcolumn = len(model.dbdata[0])
        
        if current.row()+1 == maxrow and current.column()+1 == maxcolumn:
            model.insertRow(current.row()+1, current)
            print 'row', current.row(), prev.row(), maxrow
            print 'column', current.column(), prev.column(), maxcolumn
            
    

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


class ComboBoxDelegate(QtGui.QItemDelegate):
    def __init__(self, parent = None):
        QtGui.QItemDelegate.__init__(self, parent)
        self.parent = parent

        #переопределить paint() и рисовать 2
        #разные картинки в качестве фона
        #в зависимости от того, есть ли публикация или нет.

        #переопределить setEditorData, setModelData и updateEditorGeometry
        #для изменения поведения.

    def createEditor(self, parent, option, index):
        return QtGui.QComboBox(parent)

    def setEditorData(self, comboBox, index):
        value = index.model().data(index, QtCore.Qt.EditRole)#.toInt()[0]
        comboBox.addItem(value.toString())
        comboBox.setItemText(index.row(), unicode(value.toString()))

    def setModelData(self, comboBox, model, index):
        #spinBox.interpretText()
        value = comboBox.currentText()

        model.setData(index, value, QtCore.Qt.EditRole)

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

