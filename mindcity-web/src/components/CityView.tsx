'use client';

import { FC, useState, useRef, useEffect } from 'react';
import { Building, KnowledgeItem, BuildingType, CategoryInfo, BuildingTypeInfo, getBuildingTypesForCategory, getEvolutionLevel, EvolutionInfo } from '@/lib/types';
import { calculateRetrievability } from '@/lib/fsrs';

interface CityViewProps {
  buildings: Building[];
  items: KnowledgeItem[];
  onPlaceBuilding: (itemId: string, type: BuildingType, x: number, y: number) => Promise<Building | null>;
  selectedItemId: string | null;
  onSelectItem: (id: string | null) => void;
}

const GRID_SIZE = 60;
const CITY_SIZE = 20; // 20x20 grid

const BuildingEmoji: Record<BuildingType, string> = {
  temple: '🏛️',
  garden: '🌳',
  library: '📚',
  workshop: '🔧',
  laboratory: '🔬',
  forge: '🔥',
  studio: '🎨',
  gallery: '🖼️',
  theater: '🎭',
  observatory: '🔭',
  museum: '🏛️',
  researchCenter: '🔍',
  monument: '🗿',
  milestone: '🚩',
  shrine: '✨',
  house: '🏠',
  tower: '🏢',
  archive: '🗄️',
};

const CityView: FC<CityViewProps> = ({
  buildings,
  items,
  onPlaceBuilding,
  selectedItemId,
  onSelectItem,
}) => {
  const [offset, setOffset] = useState({ x: 0, y: 0 });
  const [dragging, setDragging] = useState(false);
  const [dragMoved, setDragMoved] = useState(false);
  const [startPos, setStartPos] = useState({ x: 0, y: 0 });
  const [showBuildingPicker, setShowBuildingPicker] = useState(false);
  const [selectedCell, setSelectedCell] = useState<{ x: number; y: number } | null>(null);
  const [viewingBuilding, setViewingBuilding] = useState<Building | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const selectedItem = selectedItemId
    ? items.find(i => i.id === selectedItemId)
    : null;

  const viewingItem = viewingBuilding
    ? items.find(i => i.id === viewingBuilding.knowledgeItemId)
    : null;

  // Center the view initially
  useEffect(() => {
    if (containerRef.current) {
      const rect = containerRef.current.getBoundingClientRect();
      setOffset({
        x: rect.width / 2 - (CITY_SIZE * GRID_SIZE) / 2,
        y: rect.height / 2 - (CITY_SIZE * GRID_SIZE) / 2,
      });
    }
  }, []);

  const handlePointerDown = (e: React.PointerEvent) => {
    if (selectedItemId) return; // Don't drag when placing
    setDragging(true);
    setDragMoved(false);
    setStartPos({ x: e.clientX - offset.x, y: e.clientY - offset.y });
    (e.target as HTMLElement).setPointerCapture(e.pointerId);
  };

  const handlePointerMove = (e: React.PointerEvent) => {
    if (!dragging) return;
    const newX = e.clientX - startPos.x;
    const newY = e.clientY - startPos.y;

    // Check if we've moved more than a small threshold
    if (Math.abs(newX - offset.x) > 5 || Math.abs(newY - offset.y) > 5) {
      setDragMoved(true);
    }

    setOffset({ x: newX, y: newY });
  };

  const handlePointerUp = () => {
    setDragging(false);
  };

  const handleGridClick = (e: React.MouseEvent) => {
    if (!selectedItemId || dragging || dragMoved) return;

    const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
    const x = e.clientX - rect.left - offset.x;
    const y = e.clientY - rect.top - offset.y;

    const gridX = Math.floor(x / GRID_SIZE);
    const gridY = Math.floor(y / GRID_SIZE);

    if (gridX >= 0 && gridX < CITY_SIZE && gridY >= 0 && gridY < CITY_SIZE) {
      setSelectedCell({ x: gridX, y: gridY });
      setShowBuildingPicker(true);
    }
  };

  const handleBuildingClick = (e: React.MouseEvent, building: Building) => {
    e.stopPropagation();
    if (dragMoved) return; // Don't open if we were dragging

    // If in placement mode, don't show details
    if (selectedItemId) return;

    // Haptic feedback
    if (navigator.vibrate) navigator.vibrate(30);

    setViewingBuilding(building);
  };

  const handlePlaceBuilding = async (buildingType: BuildingType) => {
    if (!selectedItemId || !selectedCell) return;

    const posX = selectedCell.x * GRID_SIZE;
    const posY = selectedCell.y * GRID_SIZE;

    await onPlaceBuilding(selectedItemId, buildingType, posX, posY);

    setShowBuildingPicker(false);
    setSelectedCell(null);
    onSelectItem(null);
  };

  const getItemForBuilding = (building: Building) => {
    return items.find(i => i.id === building.knowledgeItemId);
  };

  const formatDate = (date: Date | string | undefined) => {
    if (!date) return 'Never';
    const d = new Date(date);
    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  };

  const getRetentionColor = (retention: number) => {
    if (retention >= 0.9) return 'text-green-500';
    if (retention >= 0.7) return 'text-yellow-500';
    return 'text-red-500';
  };

  return (
    <div
      ref={containerRef}
      className="relative w-full h-full overflow-hidden bg-gray-100 dark:bg-gray-900"
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={handlePointerUp}
      onClick={handleGridClick}
    >
      {/* Grid */}
      <div
        className="absolute city-grid"
        style={{
          width: CITY_SIZE * GRID_SIZE,
          height: CITY_SIZE * GRID_SIZE,
          transform: `translate(${offset.x}px, ${offset.y}px)`,
        }}
      >
        {/* Buildings */}
        {buildings.map((building) => {
          const item = getItemForBuilding(building);
          const evolutionLevel = item
            ? getEvolutionLevel(item.reviewCount, item.retrievability)
            : 'scaffolding';

          const daysSince = item?.lastReview
            ? (Date.now() - new Date(item.lastReview).getTime()) / (24 * 60 * 60 * 1000)
            : 0;
          const decayClass = daysSince >= 7 ? 'decay-overgrown' : daysSince >= 3 ? 'decay-muted' : '';

          // Check if due for review
          const isDue = item && new Date(item.nextReview) <= new Date();

          return (
            <div
              key={building.id}
              className={`absolute flex items-center justify-center text-3xl cursor-pointer
                transition-transform duration-200 hover:scale-110 animate-building-appear
                evolution-${evolutionLevel} ${decayClass}`}
              style={{
                left: building.positionX,
                top: building.positionY,
                width: GRID_SIZE,
                height: GRID_SIZE,
              }}
              onClick={(e) => handleBuildingClick(e, building)}
            >
              {BuildingEmoji[building.buildingType]}
              {/* Due indicator */}
              {isDue && (
                <div className="absolute -top-1 -right-1 w-3 h-3 bg-orange-500 rounded-full animate-pulse" />
              )}
            </div>
          );
        })}

        {/* Selected cell highlight */}
        {selectedCell && (
          <div
            className="absolute border-2 border-blue-500 bg-blue-100/50 dark:bg-blue-900/50 rounded"
            style={{
              left: selectedCell.x * GRID_SIZE,
              top: selectedCell.y * GRID_SIZE,
              width: GRID_SIZE,
              height: GRID_SIZE,
            }}
          />
        )}
      </div>

      {/* Placement Mode Indicator */}
      {selectedItem && (
        <div className="absolute top-4 left-4 right-4 bg-blue-500 text-white p-3 rounded-xl shadow-lg">
          <div className="flex items-center justify-between">
            <div className="flex-1 truncate">
              <span className="text-sm opacity-80">Placing:</span>
              <p className="font-medium truncate">{selectedItem.content}</p>
            </div>
            <button
              onClick={() => onSelectItem(null)}
              className="ml-2 p-2 bg-white/20 rounded-full"
            >
              ✕
            </button>
          </div>
          <p className="text-sm opacity-80 mt-1">Tap a grid cell to place a building</p>
        </div>
      )}

      {/* Building Type Picker */}
      {showBuildingPicker && selectedItem && (
        <div className="absolute inset-0 bg-black/50 flex items-end justify-center z-20">
          <div className="bg-white dark:bg-gray-900 w-full max-w-md rounded-t-3xl p-6 pb-safe">
            <h3 className="text-lg font-semibold mb-4 text-gray-900 dark:text-gray-100">Choose Building Type</h3>
            <div className="grid grid-cols-3 gap-3">
              {getBuildingTypesForCategory(selectedItem.category).map((type) => (
                <button
                  key={type}
                  onClick={() => handlePlaceBuilding(type)}
                  className="flex flex-col items-center p-4 bg-gray-100 dark:bg-gray-800 rounded-xl btn-active"
                >
                  <span className="text-3xl mb-1">{BuildingEmoji[type]}</span>
                  <span className="text-xs text-gray-600 dark:text-gray-400">{BuildingTypeInfo[type].displayName}</span>
                </button>
              ))}
            </div>
            <button
              onClick={() => {
                setShowBuildingPicker(false);
                setSelectedCell(null);
              }}
              className="w-full mt-4 py-3 text-gray-500 dark:text-gray-400"
            >
              Cancel
            </button>
          </div>
        </div>
      )}

      {/* Building Detail Sheet */}
      {viewingBuilding && viewingItem && (
        <div
          className="absolute inset-0 bg-black/50 flex items-end justify-center z-20"
          onClick={() => setViewingBuilding(null)}
        >
          <div
            className="bg-white dark:bg-gray-900 w-full max-w-md rounded-t-3xl p-6 pb-safe max-h-[80vh] overflow-auto"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Header */}
            <div className="flex items-start justify-between mb-4">
              <div className="flex items-center gap-3">
                <span className="text-4xl">{BuildingEmoji[viewingBuilding.buildingType]}</span>
                <div>
                  <h3 className="font-semibold text-gray-900 dark:text-gray-100">
                    {BuildingTypeInfo[viewingBuilding.buildingType].displayName}
                  </h3>
                  <span
                    className="text-xs px-2 py-0.5 rounded-full"
                    style={{
                      backgroundColor: CategoryInfo[viewingItem.category].color + '20',
                      color: CategoryInfo[viewingItem.category].color,
                    }}
                  >
                    {CategoryInfo[viewingItem.category].displayName}
                  </span>
                </div>
              </div>
              <button
                onClick={() => setViewingBuilding(null)}
                className="p-2 text-gray-400 hover:text-gray-600"
              >
                ✕
              </button>
            </div>

            {/* Content */}
            <div className="bg-gray-50 dark:bg-gray-800 rounded-xl p-4 mb-4">
              <p className="text-gray-900 dark:text-gray-100 whitespace-pre-wrap">
                {viewingItem.content}
              </p>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-2 gap-3 mb-4">
              <div className="bg-gray-50 dark:bg-gray-800 rounded-xl p-3">
                <p className="text-xs text-gray-500 dark:text-gray-400">Retention</p>
                <p className={`text-xl font-bold ${getRetentionColor(viewingItem.retrievability)}`}>
                  {Math.round(viewingItem.retrievability * 100)}%
                </p>
              </div>
              <div className="bg-gray-50 dark:bg-gray-800 rounded-xl p-3">
                <p className="text-xs text-gray-500 dark:text-gray-400">Reviews</p>
                <p className="text-xl font-bold text-gray-900 dark:text-gray-100">
                  {viewingItem.reviewCount}
                </p>
              </div>
              <div className="bg-gray-50 dark:bg-gray-800 rounded-xl p-3">
                <p className="text-xs text-gray-500 dark:text-gray-400">Last Review</p>
                <p className="text-sm font-medium text-gray-900 dark:text-gray-100">
                  {formatDate(viewingItem.lastReview)}
                </p>
              </div>
              <div className="bg-gray-50 dark:bg-gray-800 rounded-xl p-3">
                <p className="text-xs text-gray-500 dark:text-gray-400">Next Review</p>
                <p className="text-sm font-medium text-gray-900 dark:text-gray-100">
                  {formatDate(viewingItem.nextReview)}
                </p>
              </div>
            </div>

            {/* Evolution Status */}
            <div className="bg-gray-50 dark:bg-gray-800 rounded-xl p-3 mb-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-xs text-gray-500 dark:text-gray-400">Building Level</p>
                  <p className="font-medium text-gray-900 dark:text-gray-100">
                    {EvolutionInfo[getEvolutionLevel(viewingItem.reviewCount, viewingItem.retrievability)].displayName}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-xs text-gray-500 dark:text-gray-400">Streak</p>
                  <p className="font-medium text-gray-900 dark:text-gray-100">
                    🔥 {viewingItem.consecutiveCorrect}
                  </p>
                </div>
              </div>
            </div>

            {/* Created date */}
            <p className="text-xs text-center text-gray-400">
              Added {formatDate(viewingItem.createdAt)}
            </p>
          </div>
        </div>
      )}

      {/* Empty state */}
      {buildings.length === 0 && !selectedItemId && (
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
          <div className="text-center text-gray-500 dark:text-gray-400 p-8">
            <span className="text-6xl mb-4 block">🏗️</span>
            <h3 className="text-lg font-medium">Your city awaits</h3>
            <p className="text-sm mt-2">
              Add knowledge items and place them as buildings
            </p>
          </div>
        </div>
      )}
    </div>
  );
};

export default CityView;
