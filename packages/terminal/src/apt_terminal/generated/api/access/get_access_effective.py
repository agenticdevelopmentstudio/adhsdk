from http import HTTPStatus
from typing import Any

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.access_effective import AccessEffective
from ...models.error import Error
from ...types import UNSET, Response, Unset


def _get_kwargs(
    *,
    workspace: str,
    feature: str,
    subject_kind: str,
    subject_id: str,
    item_id: str | Unset = UNSET,
) -> dict[str, Any]:
    params: dict[str, Any] = {}

    params["workspace"] = workspace

    params["feature"] = feature

    params["subjectKind"] = subject_kind

    params["subjectId"] = subject_id

    params["itemId"] = item_id

    params = {k: v for k, v in params.items() if v is not UNSET and v is not None}

    _kwargs: dict[str, Any] = {
        "method": "get",
        "url": "/access/effective",
        "params": params,
    }

    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> AccessEffective | Error | None:
    if response.status_code == 200:
        response_200 = AccessEffective.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

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
) -> Response[AccessEffective | Error]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    *,
    client: AuthenticatedClient,
    workspace: str,
    feature: str,
    subject_kind: str,
    subject_id: str,
    item_id: str | Unset = UNSET,
) -> Response[AccessEffective | Error]:
    """A subject's effective verbs + provenance (the explainer; requires M)

    Args:
        workspace (str):
        feature (str):
        subject_kind (str):
        subject_id (str):
        item_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AccessEffective | Error]
    """

    kwargs = _get_kwargs(
        workspace=workspace,
        feature=feature,
        subject_kind=subject_kind,
        subject_id=subject_id,
        item_id=item_id,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    *,
    client: AuthenticatedClient,
    workspace: str,
    feature: str,
    subject_kind: str,
    subject_id: str,
    item_id: str | Unset = UNSET,
) -> AccessEffective | Error | None:
    """A subject's effective verbs + provenance (the explainer; requires M)

    Args:
        workspace (str):
        feature (str):
        subject_kind (str):
        subject_id (str):
        item_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AccessEffective | Error
    """

    return sync_detailed(
        client=client,
        workspace=workspace,
        feature=feature,
        subject_kind=subject_kind,
        subject_id=subject_id,
        item_id=item_id,
    ).parsed


async def asyncio_detailed(
    *,
    client: AuthenticatedClient,
    workspace: str,
    feature: str,
    subject_kind: str,
    subject_id: str,
    item_id: str | Unset = UNSET,
) -> Response[AccessEffective | Error]:
    """A subject's effective verbs + provenance (the explainer; requires M)

    Args:
        workspace (str):
        feature (str):
        subject_kind (str):
        subject_id (str):
        item_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[AccessEffective | Error]
    """

    kwargs = _get_kwargs(
        workspace=workspace,
        feature=feature,
        subject_kind=subject_kind,
        subject_id=subject_id,
        item_id=item_id,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    *,
    client: AuthenticatedClient,
    workspace: str,
    feature: str,
    subject_kind: str,
    subject_id: str,
    item_id: str | Unset = UNSET,
) -> AccessEffective | Error | None:
    """A subject's effective verbs + provenance (the explainer; requires M)

    Args:
        workspace (str):
        feature (str):
        subject_kind (str):
        subject_id (str):
        item_id (str | Unset):

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        AccessEffective | Error
    """

    return (
        await asyncio_detailed(
            client=client,
            workspace=workspace,
            feature=feature,
            subject_kind=subject_kind,
            subject_id=subject_id,
            item_id=item_id,
        )
    ).parsed
