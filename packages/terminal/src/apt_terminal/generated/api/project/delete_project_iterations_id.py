from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.delete_project_iterations_id_response_200 import DeleteProjectIterationsIdResponse200
from ...models.error import Error
from ...types import Response


def _get_kwargs(
    id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "delete",
        "url": "/project/iterations/{id}".format(
            id=quote(str(id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> DeleteProjectIterationsIdResponse200 | Error | None:
    if response.status_code == 200:
        response_200 = DeleteProjectIterationsIdResponse200.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 403:
        response_403 = Error.from_dict(response.json())

        return response_403

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[DeleteProjectIterationsIdResponse200 | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[DeleteProjectIterationsIdResponse200 | Error]:
    """Soft-delete a time-box, UN-ASSIGNING every card committed to it

     Unlike deleting a board column — which is refused while any card sits in it, because `statusId` is
    NOT NULL and there would be no answer to give — this always succeeds: `iterationId` is nullable and
    "no iteration" IS the backlog, an ordinary state. The cards are swept back there rather than
    deleted, and the response is the COUNT of them, never the cards themselves. Requires the workspace’s
    projects D verb.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DeleteProjectIterationsIdResponse200 | Error]
    """

    kwargs = _get_kwargs(
        id=id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    *,
    client: AuthenticatedClient,
) -> DeleteProjectIterationsIdResponse200 | Error | None:
    """Soft-delete a time-box, UN-ASSIGNING every card committed to it

     Unlike deleting a board column — which is refused while any card sits in it, because `statusId` is
    NOT NULL and there would be no answer to give — this always succeeds: `iterationId` is nullable and
    "no iteration" IS the backlog, an ordinary state. The cards are swept back there rather than
    deleted, and the response is the COUNT of them, never the cards themselves. Requires the workspace’s
    projects D verb.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DeleteProjectIterationsIdResponse200 | Error
    """

    return sync_detailed(
        id=id,
        client=client,
    ).parsed


async def asyncio_detailed(
    id: str,
    *,
    client: AuthenticatedClient,
) -> Response[DeleteProjectIterationsIdResponse200 | Error]:
    """Soft-delete a time-box, UN-ASSIGNING every card committed to it

     Unlike deleting a board column — which is refused while any card sits in it, because `statusId` is
    NOT NULL and there would be no answer to give — this always succeeds: `iterationId` is nullable and
    "no iteration" IS the backlog, an ordinary state. The cards are swept back there rather than
    deleted, and the response is the COUNT of them, never the cards themselves. Requires the workspace’s
    projects D verb.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[DeleteProjectIterationsIdResponse200 | Error]
    """

    kwargs = _get_kwargs(
        id=id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    *,
    client: AuthenticatedClient,
) -> DeleteProjectIterationsIdResponse200 | Error | None:
    """Soft-delete a time-box, UN-ASSIGNING every card committed to it

     Unlike deleting a board column — which is refused while any card sits in it, because `statusId` is
    NOT NULL and there would be no answer to give — this always succeeds: `iterationId` is nullable and
    "no iteration" IS the backlog, an ordinary state. The cards are swept back there rather than
    deleted, and the response is the COUNT of them, never the cards themselves. Requires the workspace’s
    projects D verb.

    Args:
        id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        DeleteProjectIterationsIdResponse200 | Error
    """

    return (
        await asyncio_detailed(
            id=id,
            client=client,
        )
    ).parsed
