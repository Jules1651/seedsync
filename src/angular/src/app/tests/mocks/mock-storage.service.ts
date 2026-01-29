import {StorageService} from "../../services/utils/local-storage.service";

export class MockStorageService implements StorageService {
    // noinspection JSUnusedLocalSymbols
    public get(key: string): any {}

    // noinspection JSUnusedLocalSymbols
    set(key: string, value: any): void {}

    // noinspection JSUnusedLocalSymbols
    remove(key: string): void {}
}
