from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_v1_shipr_repos_response_200_verbs_item import GetV1ShiprReposResponse200VerbsItem
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.get_v1_shipr_repos_response_200_items_item import (
        GetV1ShiprReposResponse200ItemsItem,
    )
    from ..models.get_v1_shipr_repos_response_200_workspace import (
        GetV1ShiprReposResponse200Workspace,
    )
    from ..models.shipr_group import ShiprGroup
    from ..models.shipr_persona import ShiprPersona


T = TypeVar("T", bound="GetV1ShiprReposResponse200")


@_attrs_define
class GetV1ShiprReposResponse200:
    """
    Attributes:
        groups (list[ShiprGroup]):
        items (list[GetV1ShiprReposResponse200ItemsItem]):
        object_ (Literal['shipr.repo'] | Unset):
        workspace (GetV1ShiprReposResponse200Workspace | Unset):
        verbs (list[GetV1ShiprReposResponse200VerbsItem] | Unset): What the caller may do at workspace level. A hint for
            what to DRAW — every route re-derives its own verb.
        personas (list[ShiprPersona] | Unset): Every persona this workspace owns — the vocabulary for
            `items[].personaIds`, carried once here rather than repeated on every row.
    """

    groups: list[ShiprGroup]
    items: list[GetV1ShiprReposResponse200ItemsItem]
    object_: Literal["shipr.repo"] | Unset = UNSET
    workspace: GetV1ShiprReposResponse200Workspace | Unset = UNSET
    verbs: list[GetV1ShiprReposResponse200VerbsItem] | Unset = UNSET
    personas: list[ShiprPersona] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        groups = []
        for groups_item_data in self.groups:
            groups_item = groups_item_data.to_dict()
            groups.append(groups_item)

        items = []
        for items_item_data in self.items:
            items_item = items_item_data.to_dict()
            items.append(items_item)

        object_ = self.object_

        workspace: dict[str, Any] | Unset = UNSET
        if not isinstance(self.workspace, Unset):
            workspace = self.workspace.to_dict()

        verbs: list[str] | Unset = UNSET
        if not isinstance(self.verbs, Unset):
            verbs = []
            for verbs_item_data in self.verbs:
                verbs_item = verbs_item_data.value
                verbs.append(verbs_item)

        personas: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.personas, Unset):
            personas = []
            for personas_item_data in self.personas:
                personas_item = personas_item_data.to_dict()
                personas.append(personas_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "groups": groups,
                "items": items,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_
        if workspace is not UNSET:
            field_dict["workspace"] = workspace
        if verbs is not UNSET:
            field_dict["verbs"] = verbs
        if personas is not UNSET:
            field_dict["personas"] = personas

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_v1_shipr_repos_response_200_items_item import (
            GetV1ShiprReposResponse200ItemsItem,
        )
        from ..models.get_v1_shipr_repos_response_200_workspace import (
            GetV1ShiprReposResponse200Workspace,
        )
        from ..models.shipr_group import ShiprGroup
        from ..models.shipr_persona import ShiprPersona

        d = dict(src_dict)
        groups = []
        _groups = d.pop("groups")
        for groups_item_data in _groups:
            groups_item = ShiprGroup.from_dict(groups_item_data)

            groups.append(groups_item)

        items = []
        _items = d.pop("items")
        for items_item_data in _items:
            items_item = GetV1ShiprReposResponse200ItemsItem.from_dict(items_item_data)

            items.append(items_item)

        object_ = cast(Literal["shipr.repo"] | Unset, d.pop("object", UNSET))
        if object_ != "shipr.repo" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'shipr.repo', got '{object_}'")

        _workspace = d.pop("workspace", UNSET)
        workspace: GetV1ShiprReposResponse200Workspace | Unset
        if isinstance(_workspace, Unset):
            workspace = UNSET
        else:
            workspace = GetV1ShiprReposResponse200Workspace.from_dict(_workspace)

        _verbs = d.pop("verbs", UNSET)
        verbs: list[GetV1ShiprReposResponse200VerbsItem] | Unset = UNSET
        if _verbs is not UNSET:
            verbs = []
            for verbs_item_data in _verbs:
                verbs_item = GetV1ShiprReposResponse200VerbsItem(verbs_item_data)

                verbs.append(verbs_item)

        _personas = d.pop("personas", UNSET)
        personas: list[ShiprPersona] | Unset = UNSET
        if _personas is not UNSET:
            personas = []
            for personas_item_data in _personas:
                personas_item = ShiprPersona.from_dict(personas_item_data)

                personas.append(personas_item)

        get_v1_shipr_repos_response_200 = cls(
            groups=groups,
            items=items,
            object_=object_,
            workspace=workspace,
            verbs=verbs,
            personas=personas,
        )

        get_v1_shipr_repos_response_200.additional_properties = d
        return get_v1_shipr_repos_response_200

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
