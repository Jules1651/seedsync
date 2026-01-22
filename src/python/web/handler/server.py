# Copyright 2017, Inderpreet Singh, All rights reserved.

import threading
from bottle import HTTPResponse

from common import Context, overrides
from ..web_app import IHandler, WebApp


class ServerHandler(IHandler):
    def __init__(self, context: Context):
        self.logger = context.logger.getChild("ServerActionHandler")
        # Use threading.Event for thread-safe restart flag communication
        self.__restart_event = threading.Event()

    @overrides(IHandler)
    def add_routes(self, web_app: WebApp):
        web_app.add_handler("/server/command/restart", self.__handle_action_restart)

    def is_restart_requested(self):
        """
        Returns true is a restart is requested
        :return:
        """
        result = self.__restart_event.is_set()
        return result

    def __handle_action_restart(self):
        """
        Request a server restart
        :return:
        """
        self.logger.info("Received a restart action, setting restart_event")
        self.__restart_event.set()
        self.logger.info("restart_event.is_set() is now: {}".format(self.__restart_event.is_set()))
        return HTTPResponse(body="Requested restart")
