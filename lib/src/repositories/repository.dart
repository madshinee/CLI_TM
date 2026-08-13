/// Generic repository interface defining the contract for data persistence.
///
/// This abstract class provides the basic CRUD operations that any
/// repository implementation must support, regardless of the entity type [T].
abstract class Repository<T> {
  /// Returns all items stored in the repository.
  Future<List<T>> getAll();

  /// Adds a new [item] to the repository.
  Future<void> add(T item);

  /// Updates an existing [item] in the repository.
  Future<void> update(T item);

  /// Deletes the item with the given [id] from the repository.
  Future<void> delete(String id);
}
