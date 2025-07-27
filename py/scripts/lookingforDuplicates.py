import os
import hashlib
from termcolor import colored

def calculate_hash(file_path, block_size=65536):
    """Вычисляет хэш файла."""
    hasher = hashlib.sha256()
    try:
        with open(file_path, 'rb') as file:
            while chunk := file.read(block_size):
                hasher.update(chunk)
    except (PermissionError, FileNotFoundError):
        return None  # Пропускаем недоступные файлы
    return hasher.hexdigest()

def find_duplicates(root_folder, size_limit_mb=10, exclude_folders=None):
    file_hashes = {}  # Словарь для хранения хэшей
    duplicates = []   # Список для хранения дубликатов
    size_limit_bytes = size_limit_mb * 1024 * 1024  # Преобразуем лимит в байты

    for foldername, _, filenames in os.walk(root_folder):
        if exclude_folders:
            if any(os.path.commonpath([foldername, ex]) == ex for ex in exclude_folders):
                continue
        
        for filename in filenames:
            file_path = os.path.join(foldername, filename)
            # Проверяем размер файла
            try:
                file_size = os.path.getsize(file_path)
            except (PermissionError, FileNotFoundError):
                continue  # Пропускаем недоступные файлы
            
            if file_size < size_limit_bytes:
                continue  # Пропускаем файлы, которые превышают лимит
            
            file_hash = calculate_hash(file_path)
            if file_hash is None:
                continue

            if file_hash in file_hashes:
                original = file_hashes[file_hash]
                duplicates.append((original,file_path))
            else:
                file_hashes[file_hash] = file_path
    return duplicates

if __name__ == "__main__":
    root = "C:\\некотики"
    size_limit = 1  # Установите лимит размера файла в МБ
    exclude_folders = ["C:\\Program Files (x86)", "C:\\Program Files", "C:\\Windows", "C:\\ProgramData"] #Не забываем вписать исключения, чтобы их не сканировало.
    print(f"Ищем дубликаты в папке: {root} (файлы больше {size_limit} МБ)...")
    duplicates_found = find_duplicates(root, size_limit, exclude_folders)

    if duplicates_found:
        print("\nНайдены следующие дубликаты:")
        item = []
        for idx, (duplicate, original) in enumerate(duplicates_found, start=1):
            print(f"Оригинал: {original}")
            print(colored(f"Дубликат: {duplicate}", 'green'))
            item.append(duplicate)
        print(f"Количество дублей: {len(item)}")
        while True:
            response = input(colored("Хотите продолжить с удалением файлов? Введите y-для каждого файла, a-подтвеждение для всех файлов, n-не удаляем\n", 'yellow')).strip().lower()
            if response == "a":
                print(colored("Удаляем все дубликаты...",'yellow'))
                for duplicate, original in duplicates_found:
                    try:
                        os.remove(duplicate)
                        print(colored(f"{duplicate} был удален.", 'red'))
                    except Exception as e:
                        print(f"WARNIN: Не удалось удалить {duplicate}: {e}")
                break
            elif response =="y":
                for duplicate, original in duplicates_found:
                    print(f"Оригинал: {original}")
                    print(colored(f"Дубликат: {duplicate}", 'green'))
                    confirm = input(colored(f"Удалить этот дубликат? [yes/no]\n", 'cyan')).strip().lower()
                    if confirm == "y":
                        try:
                            os.remove(duplicate)
                            print(colored(f"{duplicate} был удален.", 'red'))
                        except Exception as e:
                            print(f"WARNIN: Не удалось удалить {duplicate}: {e}")
                break
            else:
                print("Ничего не делаем")
                exit()
    else:
        print(colored("\nДубликаты не найдены.", 'blue'))