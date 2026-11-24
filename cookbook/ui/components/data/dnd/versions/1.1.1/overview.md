
Two distinct drag surfaces: **SortableSurface** for ordered collections (lists or multi-column boards) that report drop position as neighboring items rather than indexes — a safety measure against concurrent reordering; and **DragSurface** for unordered placement (calendar chips landing on dates, timeline bars moving along one axis). Both support pointer and keyboard interaction. The component is a thin wrapper over `@dnd-kit`, unifying its API so views speak one vocabulary for drop position and axis constraint.

