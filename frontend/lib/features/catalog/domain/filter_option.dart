class FilterOption {
  final String id;
  final String name;
  final String? icon;

  const FilterOption({
    required this.id,
    required this.name,
    this.icon,
  });

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
    );
  }
}

class FilterGroup {
  final String label;
  final List<FilterOption> options;

  const FilterGroup({required this.label, required this.options});
}
