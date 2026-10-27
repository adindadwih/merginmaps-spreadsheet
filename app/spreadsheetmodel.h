#ifndef SPREADSHEETMODEL_H
#define SPREADSHEETMODEL_H

#include <QAbstractTableModel>
#include <QPointer>
#include <QgsFeature>
#include <QgsVectorLayer>

class SpreadsheetModel : public QAbstractTableModel
{
    Q_OBJECT

    Q_PROPERTY(QgsVectorLayer *layer READ layer WRITE setLayer NOTIFY layerChanged)

  public:
    explicit SpreadsheetModel(QObject *parent = nullptr);

    QgsVectorLayer *layer() const;
    void setLayer(QgsVectorLayer *layer);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    Q_INVOKABLE QVariant cellValue(int row, int column) const;
    Q_INVOKABLE QString columnName(int column) const;
    Q_INVOKABLE QString rowLabel(int row) const;
    QVariant headerData(int section, Qt::Orientation orientation,
                        int role = Qt::DisplayRole) const override;

    bool setData(const QModelIndex &index, const QVariant &value,
                 int role = Qt::EditRole) override;

    Qt::ItemFlags flags(const QModelIndex &index) const override;

  signals:
    void layerChanged();

  private:
    QPointer<QgsVectorLayer> mLayer;
    QList<QgsFeature> mFeatures;

    void reloadFeatures();
};

#endif // SPREADSHEETMODEL_H