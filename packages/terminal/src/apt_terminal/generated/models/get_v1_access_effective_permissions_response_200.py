from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.access_effective_decided_by import AccessEffectiveDecidedBy


T = TypeVar("T", bound="GetV1AccessEffectivePermissionsResponse200")


@_attrs_define
class GetV1AccessEffectivePermissionsResponse200:
    """
    Attributes:
        item_verbs (str):
        subitem_verbs (str):
        restricted (bool):
        decided_by (AccessEffectiveDecidedBy): per-verb provenance (the explainer): verb → {kind: 'owner'|'admin-
            role'|'grant', roleSlug?, via?, scopeItemId?}; sub-item verbs keyed 'sub:<verb>'
        object_ (Literal['access.effective_permission'] | Unset):
    """

    item_verbs: str
    subitem_verbs: str
    restricted: bool
    decided_by: AccessEffectiveDecidedBy
    object_: Literal["access.effective_permission"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        item_verbs = self.item_verbs

        subitem_verbs = self.subitem_verbs

        restricted = self.restricted

        decided_by = self.decided_by.to_dict()

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "item_verbs": item_verbs,
                "subitem_verbs": subitem_verbs,
                "restricted": restricted,
                "decided_by": decided_by,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.access_effective_decided_by import AccessEffectiveDecidedBy

        d = dict(src_dict)
        item_verbs = d.pop("item_verbs")

        subitem_verbs = d.pop("subitem_verbs")

        restricted = d.pop("restricted")

        decided_by = AccessEffectiveDecidedBy.from_dict(d.pop("decided_by"))

        object_ = cast(Literal["access.effective_permission"] | Unset, d.pop("object", UNSET))
        if object_ != "access.effective_permission" and not isinstance(object_, Unset):
            raise ValueError(
                f"object must match const 'access.effective_permission', got '{object_}'"
            )

        get_v1_access_effective_permissions_response_200 = cls(
            item_verbs=item_verbs,
            subitem_verbs=subitem_verbs,
            restricted=restricted,
            decided_by=decided_by,
            object_=object_,
        )

        get_v1_access_effective_permissions_response_200.additional_properties = d
        return get_v1_access_effective_permissions_response_200

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
