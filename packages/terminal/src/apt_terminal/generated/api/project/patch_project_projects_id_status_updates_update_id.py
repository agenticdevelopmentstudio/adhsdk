from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.patch_project_projects_id_status_updates_update_id_body import (
    PatchProjectProjectsIdStatusUpdatesUpdateIdBody,
)
from ...models.project_status_update import ProjectStatusUpdate
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    update_id: str,
    *,
    body: PatchProjectProjectsIdStatusUpdatesUpdateIdBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "patch",
        "url": "/project/projects/{id}/status-updates/{update_id}".format(
            id=quote(str(id), safe=""),
            update_id=quote(str(update_id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | ProjectStatusUpdate | None:
    if response.status_code == 200:
        response_200 = ProjectStatusUpdate.from_dict(response.json())

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
) -> Response[Error | ProjectStatusUpdate]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    update_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchProjectProjectsIdStatusUpdatesUpdateIdBody | Unset = UNSET,
) -> Response[Error | ProjectStatusUpdate]:
    """Revise a status update — AUTHOR ONLY (+ a status_update.edited activity)

     The comment rule, for the identical reason: a status update carries the reporter’s name, so
    rewriting someone else’s is a forgery — and this one would additionally move a dashboard. No verb
    grants otherwise; a platform admin is the sole exception, and only because they can already reach
    the row by other means. The activity records the PREVIOUS health, because an edit that flipped a
    board from on-track to off-track is a different event from a typo fix and only the old value can
    tell them apart.

    Args:
        id (str):
        update_id (str):
        body (PatchProjectProjectsIdStatusUpdatesUpdateIdBody | Unset): At least one field is
            required (a no-op patch is a 400). AUTHOR ONLY — 403 for anyone else, whatever verbs they
            hold on the project, because a status update carries the reporter’s name.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | ProjectStatusUpdate]
    """

    kwargs = _get_kwargs(
        id=id,
        update_id=update_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    update_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchProjectProjectsIdStatusUpdatesUpdateIdBody | Unset = UNSET,
) -> Error | ProjectStatusUpdate | None:
    """Revise a status update — AUTHOR ONLY (+ a status_update.edited activity)

     The comment rule, for the identical reason: a status update carries the reporter’s name, so
    rewriting someone else’s is a forgery — and this one would additionally move a dashboard. No verb
    grants otherwise; a platform admin is the sole exception, and only because they can already reach
    the row by other means. The activity records the PREVIOUS health, because an edit that flipped a
    board from on-track to off-track is a different event from a typo fix and only the old value can
    tell them apart.

    Args:
        id (str):
        update_id (str):
        body (PatchProjectProjectsIdStatusUpdatesUpdateIdBody | Unset): At least one field is
            required (a no-op patch is a 400). AUTHOR ONLY — 403 for anyone else, whatever verbs they
            hold on the project, because a status update carries the reporter’s name.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | ProjectStatusUpdate
    """

    return sync_detailed(
        id=id,
        update_id=update_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    update_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchProjectProjectsIdStatusUpdatesUpdateIdBody | Unset = UNSET,
) -> Response[Error | ProjectStatusUpdate]:
    """Revise a status update — AUTHOR ONLY (+ a status_update.edited activity)

     The comment rule, for the identical reason: a status update carries the reporter’s name, so
    rewriting someone else’s is a forgery — and this one would additionally move a dashboard. No verb
    grants otherwise; a platform admin is the sole exception, and only because they can already reach
    the row by other means. The activity records the PREVIOUS health, because an edit that flipped a
    board from on-track to off-track is a different event from a typo fix and only the old value can
    tell them apart.

    Args:
        id (str):
        update_id (str):
        body (PatchProjectProjectsIdStatusUpdatesUpdateIdBody | Unset): At least one field is
            required (a no-op patch is a 400). AUTHOR ONLY — 403 for anyone else, whatever verbs they
            hold on the project, because a status update carries the reporter’s name.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | ProjectStatusUpdate]
    """

    kwargs = _get_kwargs(
        id=id,
        update_id=update_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    update_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchProjectProjectsIdStatusUpdatesUpdateIdBody | Unset = UNSET,
) -> Error | ProjectStatusUpdate | None:
    """Revise a status update — AUTHOR ONLY (+ a status_update.edited activity)

     The comment rule, for the identical reason: a status update carries the reporter’s name, so
    rewriting someone else’s is a forgery — and this one would additionally move a dashboard. No verb
    grants otherwise; a platform admin is the sole exception, and only because they can already reach
    the row by other means. The activity records the PREVIOUS health, because an edit that flipped a
    board from on-track to off-track is a different event from a typo fix and only the old value can
    tell them apart.

    Args:
        id (str):
        update_id (str):
        body (PatchProjectProjectsIdStatusUpdatesUpdateIdBody | Unset): At least one field is
            required (a no-op patch is a 400). AUTHOR ONLY — 403 for anyone else, whatever verbs they
            hold on the project, because a status update carries the reporter’s name.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | ProjectStatusUpdate
    """

    return (
        await asyncio_detailed(
            id=id,
            update_id=update_id,
            client=client,
            body=body,
        )
    ).parsed
