# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'main_window.ui'
#
# Created: Mon Feb  7 17:11:18 2011
#      by: PyQt4 UI code generator 4.7.3
#
# WARNING! All changes made in this file will be lost!

from PyQt4 import QtCore, QtGui

class MainWindow(object):
    def setupUi(self, MainWindow):
        MainWindow.setObjectName("MainWindow")
        MainWindow.resize(643, 468)
        self.centralwidget = QtGui.QWidget(MainWindow)
        self.centralwidget.setObjectName("centralwidget")
        self.verticalLayout = QtGui.QVBoxLayout(self.centralwidget)
        self.verticalLayout.setObjectName("verticalLayout")
        self.tabWidget = QtGui.QTabWidget(self.centralwidget)
        self.tabWidget.setTabPosition(QtGui.QTabWidget.South)
        self.tabWidget.setTabShape(QtGui.QTabWidget.Rounded)
        self.tabWidget.setObjectName("tabWidget")
        self.stations_tab = QtGui.QWidget()
        self.stations_tab.setObjectName("stations_tab")
        self.verticalLayout_2 = QtGui.QVBoxLayout(self.stations_tab)
        self.verticalLayout_2.setObjectName("verticalLayout_2")
        self.stationsTableView = QtGui.QTableView(self.stations_tab)
        self.stationsTableView.setObjectName("stationsTableView")
        self.verticalLayout_2.addWidget(self.stationsTableView)
        self.tabWidget.addTab(self.stations_tab, "")
        self.catch_tab = QtGui.QWidget()
        self.catch_tab.setObjectName("catch_tab")
        self.verticalLayout_3 = QtGui.QVBoxLayout(self.catch_tab)
        self.verticalLayout_3.setObjectName("verticalLayout_3")
        self.catchTableView = QtGui.QTableView(self.catch_tab)
        self.catchTableView.setObjectName("catchTableView")
        self.verticalLayout_3.addWidget(self.catchTableView)
        self.tabWidget.addTab(self.catch_tab, "")
        self.bio_tab = QtGui.QWidget()
        self.bio_tab.setObjectName("bio_tab")
        self.verticalLayout_4 = QtGui.QVBoxLayout(self.bio_tab)
        self.verticalLayout_4.setObjectName("verticalLayout_4")
        self.bioTableView = QtGui.QTableView(self.bio_tab)
        self.bioTableView.setObjectName("bioTableView")
        self.verticalLayout_4.addWidget(self.bioTableView)
        self.tabWidget.addTab(self.bio_tab, "")
        self.verticalLayout.addWidget(self.tabWidget)
        MainWindow.setCentralWidget(self.centralwidget)
        self.menubar = QtGui.QMenuBar(MainWindow)
        self.menubar.setGeometry(QtCore.QRect(0, 0, 643, 18))
        self.menubar.setObjectName("menubar")
        MainWindow.setMenuBar(self.menubar)
        self.statusbar = QtGui.QStatusBar(MainWindow)
        self.statusbar.setObjectName("statusbar")
        MainWindow.setStatusBar(self.statusbar)

        self.retranslateUi(MainWindow)
        self.tabWidget.setCurrentIndex(0)
        QtCore.QMetaObject.connectSlotsByName(MainWindow)

    def retranslateUi(self, MainWindow):
        MainWindow.setWindowTitle(QtGui.QApplication.translate("MainWindow", "MainWindow", None, QtGui.QApplication.UnicodeUTF8))
        self.tabWidget.setTabText(self.tabWidget.indexOf(self.stations_tab), QtGui.QApplication.translate("MainWindow", "Станции", None, QtGui.QApplication.UnicodeUTF8))
        self.tabWidget.setTabText(self.tabWidget.indexOf(self.catch_tab), QtGui.QApplication.translate("MainWindow", "Уловы", None, QtGui.QApplication.UnicodeUTF8))
        self.tabWidget.setTabText(self.tabWidget.indexOf(self.bio_tab), QtGui.QApplication.translate("MainWindow", "Биоанализы", None, QtGui.QApplication.UnicodeUTF8))

