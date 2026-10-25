enum SortMode {
  byTime('Sort by time'),
  byPriority('Sort by priority'),
  custom('Custom (hold & drag)');

  const SortMode(this.label);

  final String label;
}
