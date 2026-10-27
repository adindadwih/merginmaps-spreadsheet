#include "spreadsheetmodel.h"

#include <QgsFields>
#include <QgsFeatureRequest>
#include <QgsField>
#include <QgsVectorDataProvider>

SpreadsheetModel::SpreadsheetModel(QObject *parent)
  : QAbstractTableModel(parent)
{
}

QgsVectorLayer *SpreadsheetModel::layer() const
{
  return mLayer.data();
}

void SpreadsheetModel::setLayer(QgsVectorLayer *layer)
{
  if (mLayer == layer)
    return;

  if (mLayer)
    disconnect(mLayer, nullptr, this, nullptr);

  beginResetModel();
  mLayer = layer;
  mFeatures.clear();

  if (mLayer)
  {
    connect(mLayer, &QObject::destroyed, this, [this]()
    {
      beginResetModel();
      mLayer = nullptr;
      mFeatures.clear();
      endResetModel();
      emit layerChanged();
    });

    connect(mLayer, &QgsVectorLayer::attributeValueChanged,
        this, [this](QgsFeatureId featureId, int fieldIndex, const QVariant &value)
    {
      for (int row = 0; row < mFeatures.count(); ++row)
      {
        if (mFeatures.at(row).id() == featureId)
        {
          mFeatures[row].setAttribute(fieldIndex, value);

          const QModelIndex changedIndex = index(row, fieldIndex);
          emit dataChanged(changedIndex, changedIndex,
                           {Qt::DisplayRole, Qt::EditRole});
          break;
        }
      }
    });

    connect(mLayer, &QgsVectorLayer::featureAdded,
            this, [this](QgsFeatureId)
    {
      reloadFeatures();
    });

    connect(mLayer, &QgsVectorLayer::featuresDeleted,
            this, [this](const QgsFeatureIds &)
    {
      reloadFeatures();
    });

    QgsFeature feature;
    QgsFeatureIterator iterator = mLayer->getFeatures();

    while (iterator.nextFeature(feature))
      mFeatures.append(feature);
  }

  endResetModel();
  emit layerChanged();
}

int SpreadsheetModel::rowCount(const QModelIndex &parent) const
{
  if (parent.isValid())
    return 0;

  return mFeatures.count();
}

int SpreadsheetModel::columnCount(const QModelIndex &parent) const
{
  if (parent.isValid() || !mLayer)
    return 0;

  return mLayer->fields().count();
}

QVariant SpreadsheetModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid() ||
      index.row() < 0 || index.row() >= mFeatures.count() ||
      index.column() < 0 || index.column() >= columnCount())
    return {};

  if (role == Qt::DisplayRole || role == Qt::EditRole)
    return mFeatures.at(index.row()).attribute(index.column());

  return {};
}

QVariant SpreadsheetModel::headerData(
    int section, Qt::Orientation orientation, int role) const
{
  if (role != Qt::DisplayRole || !mLayer)
    return {};

  if (orientation == Qt::Horizontal)
  {
    const QgsFields fields = mLayer->fields();

    if (section >= 0 && section < fields.count())
      return fields.at(section).name();
  }
  else
  {
    if (section >= 0 && section < mFeatures.count())
      return section + 1;
  }

  return {};
}

bool SpreadsheetModel::setData(
    const QModelIndex &index, const QVariant &value, int role)
{
  if (role != Qt::EditRole || !index.isValid() || !mLayer)
    return false;

  if (index.row() < 0 || index.row() >= mFeatures.count() ||
      index.column() < 0 || index.column() >= columnCount())
    return false;

  if (mLayer->isReadOnly())
    return false;

  if (!mLayer->isEditable() && !mLayer->startEditing())
    return false;

  const QgsFeatureId featureId = mFeatures.at(index.row()).id();

  if (!mLayer->changeAttributeValue(featureId, index.column(), value))
    return false;

  mFeatures[index.row()].setAttribute(index.column(), value);

  emit dataChanged(index, index, {Qt::DisplayRole, Qt::EditRole});
  return true;
}

Qt::ItemFlags SpreadsheetModel::flags(const QModelIndex &index) const
{
  if (!index.isValid())
    return Qt::NoItemFlags;

  Qt::ItemFlags itemFlags = Qt::ItemIsEnabled | Qt::ItemIsSelectable;

  if (mLayer && !mLayer->isReadOnly())
    itemFlags |= Qt::ItemIsEditable;

  return itemFlags;
}

void SpreadsheetModel::reloadFeatures()
{
  if (!mLayer)
    return;

  beginResetModel();
  mFeatures.clear();

  QgsFeature feature;
  QgsFeatureIterator iterator = mLayer->getFeatures();

  while (iterator.nextFeature(feature))
    mFeatures.append(feature);

  endResetModel();
}

QVariant SpreadsheetModel::cellValue(int row, int column) const
{
  if (row < 0 || row >= mFeatures.count() ||
      column < 0 || column >= columnCount())
    return {};

  return mFeatures.at(row).attribute(column);
}

QString SpreadsheetModel::columnName(int column) const
{
  if (!mLayer || column < 0 || column >= mLayer->fields().count())
    return {};

  return mLayer->fields().at(column).name();
}

QString SpreadsheetModel::rowLabel(int row) const
{
  if (row < 0 || row >= mFeatures.count())
    return {};

  return QString::number(row + 1);
}