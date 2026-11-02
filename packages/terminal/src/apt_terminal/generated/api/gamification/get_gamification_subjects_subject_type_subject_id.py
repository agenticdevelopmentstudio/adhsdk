from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.gamification_summary import GamificationSummary
from ...types import Response


def _get_kwargs(
    subject_type: str,
    subject_id: str,
) -> dict[str, Any]:
    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/gamification/subjects/{subject_type}/{subject_id}".format(
            subject_type=quote(str(subject_type), safe=""),
            subject_id=quote(str(subject_id), safe=""),
        ),
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | GamificationSummary | None:
    if response.status_code == 200:
        response_200 = GamificationSummary.from_dict(response.json())

        return response_200

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | GamificationSummary]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    subject_type: str,
    subject_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | GamificationSummary]:
    """A subject’s gamification summary (points, level, badges, opt-out)

    Args:
        subject_type (str):
        subject_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GamificationSummary]
    """

    kwargs = _get_kwargs(
        subject_type=subject_type,
        subject_id=subject_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    subject_type: str,
    subject_id: str,
    *,
    client: AuthenticatedClient,
) -> Error | GamificationSummary | None:
    """A subject’s gamification summary (points, level, badges, opt-out)

    Args:
        subject_type (str):
        subject_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GamificationSummary
    """

    return sync_detailed(
        subject_type=subject_type,
        subject_id=subject_id,
        client=client,
    ).parsed


async def asyncio_detailed(
    subject_type: str,
    subject_id: str,
    *,
    client: AuthenticatedClient,
) -> Response[Error | GamificationSummary]:
    """A subject’s gamification summary (points, level, badges, opt-out)

    Args:
        subject_type (str):
        subject_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | GamificationSummary]
    """

    kwargs = _get_kwargs(
        subject_type=subject_type,
        subject_id=subject_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    subject_type: str,
    subject_id: str,
    *,
    client: AuthenticatedClient,
) -> Error | GamificationSummary | None:
    """A subject’s gamification summary (points, level, badges, opt-out)

    Args:
        subject_type (str):
        subject_id (str):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | GamificationSummary
    """

    return (
        await asyncio_detailed(
            subject_type=subject_type,
            subject_id=subject_id,
            client=client,
        )
    ).parsed
