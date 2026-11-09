from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.archived_workspace_type import ArchivedWorkspaceType

T = TypeVar("T", bound="ArchivedWorkspace")


@_attrs_define
class ArchivedWorkspace:
    """
    Attributes:
        id (str): The organization id — what POST /organization/organizations/{id}/restore takes
        slug (str):
        name (str):
        type_ (ArchivedWorkspaceType):
        archived_at (str): When the organization was archived (DB timestamp text, not RFC3339)
        handle_available (bool): False once org.<slug> has been claimed by someone else — a restore would 409
        can_restore (bool): False when the caller can see the org (they are a member) but may not restore it. True for
            the org's creator, an admin of one of its live org-owned teams, or a site admin.
    """

    id: str
    slug: str
    name: str
    type_: ArchivedWorkspaceType
    archived_at: str
    handle_available: bool
    can_restore: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        slug = self.slug

        name = self.name

        type_ = self.type_.value

        archived_at = self.archived_at

        handle_available = self.handle_available

        can_restore = self.can_restore

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "slug": slug,
                "name": name,
                "type": type_,
                "archived_at": archived_at,
                "handle_available": handle_available,
                "can_restore": can_restore,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        slug = d.pop("slug")

        name = d.pop("name")

        type_ = ArchivedWorkspaceType(d.pop("type"))

        archived_at = d.pop("archived_at")

        handle_available = d.pop("handle_available")

        can_restore = d.pop("can_restore")

        archived_workspace = cls(
            id=id,
            slug=slug,
            name=name,
            type_=type_,
            archived_at=archived_at,
            handle_available=handle_available,
            can_restore=can_restore,
        )

        archived_workspace.additional_properties = d
        return archived_workspace

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
