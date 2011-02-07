#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys

from PyQt4 import QtCore, QtGui
from main_window import MainWindow

class MainView(QtGui.QMainWindow):
    
    #Инициализация главного окна
    def __init__(self, parent = None):
        QtGui.QMainWindow.__init__(self, parent)
        self.ui = MainWindow()
        self.ui.setupUi(self)


def main():

    app = QtGui.QApplication(sys.argv)
    app.setStyle('cleanlooks')
    translator = QtCore.QTranslator(app)
    translator.load("qt_ru.qm")
    app.installTranslator(translator)
    window=MainView()
    window.setWindowTitle(u'База данных')
    window.show()
    sys.exit(app.exec_())

if __name__ == "__main__":
    main()

