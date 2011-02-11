#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys

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

#надо добавить год, судно, номер рейса, наблюдатель

station_headers = {'station_number':u'станция', 'journ_station':u'№ в судовом журнале', 'begdate':u'дата постановки', 'begtime':u'время постановки', 'enddate':u'дата выборки', 'enttime':u'время выборки', 'begdepth':u'глубина начала', 'enddepth':u'глубина конца', 'bottomcode':u'грунт', 'beglatgrad beglatmin beglonggrad beglongmin':u'координаты начала', 'endlatgrad endlatmin endlonggrad endlongmin':u'координаты конца', 'begdepth':u'глубина начала', 'enddepth':u'глубина конца', 'gearcode':u'орудие лова', '???':u'вид наживки', '????':u'ячея', 'trapdist':u'расстояние между ловушками', 'nlov':u'число ловушек', '?????':u'обработано', 'pressure':u'атм. давление, МПа', 'surfacetemp':u'Т возд.,°С', 'windspeed':u'V ветра, м/с', 'winddirection':u'направление ветра', 'wave':u'волнение', 'temp':u'Т воды.,°С'}

catch_headers = [u'№ станции', u'вид', u'улов', u'комм. улов', u'вес пробы', u'пром. самцы, шт', u'непром. самцы, шт', u'самки, шт', u'комментарий',]

bio_groups = {'krill':u'криль', 'krevet':u'креветки', 'squid':u'головоногие', 'echinoidea':u'ежи', 'crab':u'крабы', 'squid':u'головоногие', 'algae':u'водоросли', 'golotur':u'голотурии', 'molusk':u'брюхоногие', 'pelecipoda':u'двустворчатые'}

bio_headers = {'shellheight':u'высота раковины', 'bodywght':u'общий вес', 'myear':u'год', 'weight':u'вес', 'shelllength':u'длина раковины', 'stageovary':u'стадия зрелости яичника', 'numspec':u'номер особи', 'sex':u'пол', 'kmmweight':u'вес кожно-мускульного мешка', 'comment3':u'комментарий', 'gonadweight':u'вес гонады', 'gonad':u'стадия развития гонады', 'stagepetasma':u'стадия петазмы', 'condgenapert':u'состояние половых отверстий', 'leglost':u'повреждения ног', 'mlength':u'промысловая длина тела', 'stagetelicum':u'стадия теликума', 'sternal':u'стернальные шипы', 'label':u'метка', 'gonadcolor':u'цвет гонад', 'moltingst':u'линочная стадия', 'numstrat':u'номер страты', 'speciescode':u'вид', 'eggs':u'икра', 'bodydiametr':u'диаметр тела', 'gonadindex':u'гонадный индекс', 'stomach':u'наполнение желудка', 'clawhight':u'высота клешни', 'condspf':u'состояние сперматофоров', 'spermball':u'наличие шарика спермы', 'maturstage':u'стадия зрелости', 'vesselcode':u'судно', 'substagemat':u'подстадия зрелости', 'bodyheight':u'высота панциря', 'gonadwght':u'вес гонад', 'bodyweight':u'вес тела', 'numstn':u'номер станции', 'shellwidth':u'ширина раковины', 'observcode':u'наблюдатель', 'stagemat':u'стадия зрелости', 'wkarapax':u'ширина карапакса', 'comment4':u'комментарий', 'age':u'возраст', 'numsurvey':u'номер рейса', 'comment1':u'комментарий', 'condamp':u'состояние ампул', 'lkarapax':u'длина карапакса', 'comment2':u'комментарий', 'illnesscode':u'заболевание', 'musclewght':u'вес мускула', 'spfform':u'форма сперматофоров', 'mating':u'следы спаривания'}

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

        
        self.cur.execute(column_names_query % 'stations')
        
        for i in self.cur.fetchall():
            print i[0]
        

        #пока так...
        self.ui.stationsTableView.setModel(TableModel([range(1,26), station_headers.keys(), station_headers.values()], station_headers.values(), self.undoStack, self.conn, self.statusBar, station_headers.keys(), self))
        self.ui.catchTableView.setModel(TableModel([range(1,10),], catch_headers, self.undoStack, self.conn, self.statusBar, catch_headers, self))
        

      
        self.ui.bioTableView.setModel(TableModel([range(1,54),], bio_headers.values(), self.undoStack, self.conn, self.statusBar, bio_headers.values, self))


        #Delegate работает
        delegate = ColumnDelegate(self.ui.bioTableView.model())
        self.ui.bioTableView.setItemDelegateForColumn(0,delegate)


        #Потом, в зависимости от вида, прятать те или иные колонки. Отображаться колонки будут для того вида, который в настоящий момент 
        #выбран. Прописано это поведение будет прямо в модели. То же самое придется делать и для станций и для уловов. Поэтому
        #еще раз пишу - надо переделать модель!!! для всех!!!

        self.connect(self.ui.comboBox, QtCore.SIGNAL("activated(int)"), self.test)

        #self.hideColumns(self.ui.bioTableView, [1,2,3,4,5,6,7])
        
    def test(self):
        self.ui.bioTableView.model().insertRow(self.ui.bioTableView.currentIndex(), 1)

    def hideColumns(self, table, columns):
        
        for i in columns:
            table.hideColumn(i)
        


class TableModel(QtCore.QAbstractTableModel):
    def __init__(self, datain, headerdata, undostack, conn, statusbar, columns, parent=None, *args):
        QtCore.QAbstractTableModel.__init__(self, parent, *args)
        self.cur = conn.cursor()
        self.statusbar = statusbar
        self.undostack = undostack
        self.dbdata = datain
        self.header = headerdata
        self.columns = columns
       
    def insertRow(self, index, row):
        new_row = []
        for i in xrange(len(self.dbdata[0])):
            new_row.append("")
                
        self.beginInsertRows(index, row, row)
        self.dbdata.append(new_row)
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


class ColumnDelegate(QtGui.QItemDelegate):
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
        value = index.model().data(index, QtCore.Qt.EditRole).toInt()[0]
        comboBox.addItem(QtCore.QString(value))
        comboBox.setItemText(index.row(), str(value))

        def setModelData(self, spinBox, model, index):
            spinBox.interpretText()
            value = spinBox.value()

            model.setData(index, value, QtCore.Qt.EditRole)

    def updateEditorGeometry(self, editor, option, index):
        editor.setGeometry(option.rect)


    #def paint(self, painter, option, index):
    #    painter.save()
    #
        # set background color
    #    painter.setPen(QtGui.QPen(QtGui.Qt.NoPen))
    #    if option.state & QtGui.QStyle.State_Selected:
    #        painter.setBrush(QtGui.QBrush(QtGui.Qt.red))
    #    else:
    #        painter.setBrush(QtGyu.QBrush(QtGui.Qt.white))
    #    painter.drawRect(option.rect)

        # set text color
    #    painter.setPen(QtGui.QPen(QtGui.Qt.black))
    #    value = index.data(QtGui.Qt.DisplayRole)
    #    if value.isValid():
    #        text = value.toString()
    #        painter.drawText(option.rect, QtGui.Qt.AlignLeft, text)

    #painter.restore()




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

