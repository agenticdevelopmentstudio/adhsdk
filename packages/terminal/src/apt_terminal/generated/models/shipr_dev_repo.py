from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="ShiprDevRepo")


@_attrs_define
class ShiprDevRepo:
    """The source repository a mirror is fed from.

    Attributes:
        id (str | Unset):
        slug (str | Unset):
        display_name (None | str | Unset): What the operator calls it, which is not always what the forge calls it. Null
            means no opinion and every reader falls back to `slug`. A LABEL AND NOTHING MORE: no branch, no path and no
            forge call is derived from it.
        main_branch (str | Unset):
        prepared_branch (str | Unset):
        declaration_sha (None | str | Unset):
        connection_id (None | str | Unset):
    """

    id: str | Unset = UNSET
    slug: str | Unset = UNSET
    display_name: None | str | Unset = UNSET
    main_branch: str | Unset = UNSET
    prepared_branch: str | Unset = UNSET
    declaration_sha: None | str | Unset = UNSET
    connection_id: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        slug = self.slug

        display_name: None | str | Unset
        if isinstance(self.display_name, Unset):
            display_name = UNSET
        else:
            display_name = self.display_name

        main_branch = self.main_branch

        prepared_branch = self.prepared_branch

        declaration_sha: None | str | Unset
        if isinstance(self.declaration_sha, Unset):
            declaration_sha = UNSET
        else:
            declaration_sha = self.declaration_sha

        connection_id: None | str | Unset
        if isinstance(self.connection_id, Unset):
            connection_id = UNSET
        else:
            connection_id = self.connection_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if id is not UNSET:
            field_dict["id"] = id
        if slug is not UNSET:
            field_dict["slug"] = slug
        if display_name is not UNSET:
            field_dict["display_name"] = display_name
        if main_branch is not UNSET:
            field_dict["main_branch"] = main_branch
        if prepared_branch is not UNSET:
            field_dict["prepared_branch"] = prepared_branch
        if declaration_sha is not UNSET:
            field_dict["declaration_sha"] = declaration_sha
        if connection_id is not UNSET:
            field_dict["connection_id"] = connection_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id", UNSET)

        slug = d.pop("slug", UNSET)

        def _parse_display_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        display_name = _parse_display_name(d.pop("display_name", UNSET))

        main_branch = d.pop("main_branch", UNSET)

        prepared_branch = d.pop("prepared_branch", UNSET)

        def _parse_declaration_sha(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        declaration_sha = _parse_declaration_sha(d.pop("declaration_sha", UNSET))

        def _parse_connection_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        connection_id = _parse_connection_id(d.pop("connection_id", UNSET))

        shipr_dev_repo = cls(
            id=id,
            slug=slug,
            display_name=display_name,
            main_branch=main_branch,
            prepared_branch=prepared_branch,
            declaration_sha=declaration_sha,
            connection_id=connection_id,
        )

        shipr_dev_repo.additional_properties = d
        return shipr_dev_repo

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
