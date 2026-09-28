import asyncio
import logging
from hello import __version__

from asyncua import Server, ua

ENDPOINT = "opc.tcp://0.0.0.0:4840/hello/server/"
NAMESPACE = "http://hello.vscode.docker"


async def main() -> None:
    server = Server()
    await server.init()
    server.set_endpoint(ENDPOINT)
    server.set_server_name("Hello OPC UA Server")

    idx = await server.register_namespace(NAMESPACE)
    hello_obj = await server.nodes.objects.add_object(idx, "Hello")
    counter = await hello_obj.add_variable(idx, "Counter", 0, ua.VariantType.Int64)
    await counter.set_writable()

    logging.info(f"Hello OPC UA Server is serving on {ENDPOINT}")

    async with server:
        while True:
            try:
                await asyncio.sleep(1)
                await counter.write_value((await counter.read_value()) + 1)
            except asyncio.exceptions.CancelledError:
                logging.critical("Server interrupted by user")
                break


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    logging.getLogger("asyncua").setLevel(logging.WARNING)
    logging.info(f"Hello OPC UA Server version: {__version__}")
    asyncio.run(main())
