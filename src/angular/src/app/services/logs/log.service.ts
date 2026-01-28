import {Injectable, OnDestroy} from "@angular/core";
import {Observable} from "rxjs/Observable";
import {ReplaySubject} from "rxjs/ReplaySubject";
import {Subject} from "rxjs/Subject";

import {BaseStreamService} from "../base/base-stream.service";
import {LogRecord} from "./log-record";


@Injectable()
export class LogService extends BaseStreamService implements OnDestroy {
    private destroy$ = new Subject<void>();

    private _logs: ReplaySubject<LogRecord> = new ReplaySubject();

    constructor() {
        super();
        this.registerEventName("log-record");
    }

    /**
     * Logs is a hot observable (i.e. no caching)
     * @returns {Observable<LogRecord>}
     */
    get logs(): Observable<LogRecord> {
        return this._logs.asObservable();
    }

    protected onEvent(eventName: string, data: string) {
        this._logs.next(LogRecord.fromJson(JSON.parse(data)));
    }

    protected onConnected() {
        // nothing to do
    }

    protected onDisconnected() {
        // nothing to do
    }

    ngOnDestroy() {
        this.destroy$.next();
        this.destroy$.complete();
    }
}
