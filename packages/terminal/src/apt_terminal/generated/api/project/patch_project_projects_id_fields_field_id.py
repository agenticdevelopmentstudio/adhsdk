from http import HTTPStatus
from typing import Any
from urllib.parse import quote

import httpx

from ... import errors
from ...client import AuthenticatedClient, Client
from ...models.error import Error
from ...models.patch_project_projects_id_fields_field_id_body import (
    PatchProjectProjectsIdFieldsFieldIdBody,
)
from ...models.project_field import ProjectField
from ...types import UNSET, Response, Unset


def _get_kwargs(
    id: str,
    field_id: str,
    *,
    body: PatchProjectProjectsIdFieldsFieldIdBody | Unset = UNSET,
) -> dict[str, Any]:
    headers: dict[str, Any] = {}

    _kwargs: dict[str, Any] = {
        "method": "patch",
        "url": "/project/projects/{id}/fields/{field_id}".format(
            id=quote(str(id), safe=""),
            field_id=quote(str(field_id), safe=""),
        ),
    }

    if not isinstance(body, Unset):
        _kwargs["json"] = body.to_dict()

    headers["Content-Type"] = "application/json"

    _kwargs["headers"] = headers
    return _kwargs


def _parse_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Error | ProjectField | None:
    if response.status_code == 200:
        response_200 = ProjectField.from_dict(response.json())

        return response_200

    if response.status_code == 400:
        response_400 = Error.from_dict(response.json())

        return response_400

    if response.status_code == 401:
        response_401 = Error.from_dict(response.json())

        return response_401

    if response.status_code == 404:
        response_404 = Error.from_dict(response.json())

        return response_404

    if client.raise_on_unexpected_status:
        raise errors.UnexpectedStatus(response.status_code, response.content)
    else:
        return None


def _build_response(
    *, client: AuthenticatedClient | Client, response: httpx.Response
) -> Response[Error | ProjectField]:
    return Response(
        status_code=HTTPStatus(response.status_code),
        content=response.content,
        headers=response.headers,
        parsed=_parse_response(client=client, response=response),
    )


def sync_detailed(
    id: str,
    field_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchProjectProjectsIdFieldsFieldIdBody | Unset = UNSET,
) -> Response[Error | ProjectField]:
    """Relabel / retype / reorder a field (+ a field.updated activity)

    Args:
        id (str):
        field_id (str):
        body (PatchProjectProjectsIdFieldsFieldIdBody | Unset): At least one mutable field is
            required (a no-op patch is a 400). `key` is immutable.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | ProjectField]
    """

    kwargs = _get_kwargs(
        id=id,
        field_id=field_id,
        body=body,
    )

    response = client.get_httpx_client().request(
        **kwargs,
    )

    return _build_response(client=client, response=response)


def sync(
    id: str,
    field_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchProjectProjectsIdFieldsFieldIdBody | Unset = UNSET,
) -> Error | ProjectField | None:
    """Relabel / retype / reorder a field (+ a field.updated activity)

    Args:
        id (str):
        field_id (str):
        body (PatchProjectProjectsIdFieldsFieldIdBody | Unset): At least one mutable field is
            required (a no-op patch is a 400). `key` is immutable.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | ProjectField
    """

    return sync_detailed(
        id=id,
        field_id=field_id,
        client=client,
        body=body,
    ).parsed


async def asyncio_detailed(
    id: str,
    field_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchProjectProjectsIdFieldsFieldIdBody | Unset = UNSET,
) -> Response[Error | ProjectField]:
    """Relabel / retype / reorder a field (+ a field.updated activity)

    Args:
        id (str):
        field_id (str):
        body (PatchProjectProjectsIdFieldsFieldIdBody | Unset): At least one mutable field is
            required (a no-op patch is a 400). `key` is immutable.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Response[Error | ProjectField]
    """

    kwargs = _get_kwargs(
        id=id,
        field_id=field_id,
        body=body,
    )

    response = await client.get_async_httpx_client().request(**kwargs)

    return _build_response(client=client, response=response)


async def asyncio(
    id: str,
    field_id: str,
    *,
    client: AuthenticatedClient,
    body: PatchProjectProjectsIdFieldsFieldIdBody | Unset = UNSET,
) -> Error | ProjectField | None:
    """Relabel / retype / reorder a field (+ a field.updated activity)

    Args:
        id (str):
        field_id (str):
        body (PatchProjectProjectsIdFieldsFieldIdBody | Unset): At least one mutable field is
            required (a no-op patch is a 400). `key` is immutable.

    Raises:
        errors.UnexpectedStatus: If the server returns an undocumented status code and Client.raise_on_unexpected_status is True.
        httpx.TimeoutException: If the request takes longer than Client.timeout.

    Returns:
        Error | ProjectField
    """

    return (
        await asyncio_detailed(
            id=id,
            field_id=field_id,
            client=client,
            body=body,
        )
    ).parsed
