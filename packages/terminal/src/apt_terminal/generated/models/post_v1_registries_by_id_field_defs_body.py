from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_registries_by_id_field_defs_body_type import (
    PostV1RegistriesByIdFieldDefsBodyType,
)
from ..models.post_v1_registries_by_id_field_defs_body_visibility import (
    PostV1RegistriesByIdFieldDefsBodyVisibility,
)
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_registries_by_id_field_defs_body_config import (
        PostV1RegistriesByIdFieldDefsBodyConfig,
    )
    from ..models.post_v1_registries_by_id_field_defs_body_show_if_type_0 import (
        PostV1RegistriesByIdFieldDefsBodyShowIfType0,
    )


T = TypeVar("T", bound="PostV1RegistriesByIdFieldDefsBody")


@_attrs_define
class PostV1RegistriesByIdFieldDefsBody:
    """
    Attributes:
        section_id (str):
        key (str):
        type_ (PostV1RegistriesByIdFieldDefsBodyType):
        label (str):
        help_ (str | Unset):
        required (bool | Unset):
        sort_order (int | Unset):
        config (PostV1RegistriesByIdFieldDefsBodyConfig | Unset):
        visibility (PostV1RegistriesByIdFieldDefsBodyVisibility | Unset): Omitted: derived from `type` by
            `defaultVisibilityForType` — a contact type (email, phone, address) starts 'private', everything else 'public'.
            The default is where the contact-privacy protection lives; publishing a phone number is a decision the owner
            makes, not one they inherit.
        show_if (None | PostV1RegistriesByIdFieldDefsBodyShowIfType0 | Unset):
    """

    section_id: str
    key: str
    type_: PostV1RegistriesByIdFieldDefsBodyType
    label: str
    help_: str | Unset = UNSET
    required: bool | Unset = UNSET
    sort_order: int | Unset = UNSET
    config: PostV1RegistriesByIdFieldDefsBodyConfig | Unset = UNSET
    visibility: PostV1RegistriesByIdFieldDefsBodyVisibility | Unset = UNSET
    show_if: None | PostV1RegistriesByIdFieldDefsBodyShowIfType0 | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_registries_by_id_field_defs_body_show_if_type_0 import (
            PostV1RegistriesByIdFieldDefsBodyShowIfType0,
        )

        section_id = self.section_id

        key = self.key

        type_ = self.type_.value

        label = self.label

        help_ = self.help_

        required = self.required

        sort_order = self.sort_order

        config: dict[str, Any] | Unset = UNSET
        if not isinstance(self.config, Unset):
            config = self.config.to_dict()

        visibility: str | Unset = UNSET
        if not isinstance(self.visibility, Unset):
            visibility = self.visibility.value

        show_if: dict[str, Any] | None | Unset
        if isinstance(self.show_if, Unset):
            show_if = UNSET
        elif isinstance(self.show_if, PostV1RegistriesByIdFieldDefsBodyShowIfType0):
            show_if = self.show_if.to_dict()
        else:
            show_if = self.show_if

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "section_id": section_id,
                "key": key,
                "type": type_,
                "label": label,
            }
        )
        if help_ is not UNSET:
            field_dict["help"] = help_
        if required is not UNSET:
            field_dict["required"] = required
        if sort_order is not UNSET:
            field_dict["sort_order"] = sort_order
        if config is not UNSET:
            field_dict["config"] = config
        if visibility is not UNSET:
            field_dict["visibility"] = visibility
        if show_if is not UNSET:
            field_dict["show_if"] = show_if

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_registries_by_id_field_defs_body_config import (
            PostV1RegistriesByIdFieldDefsBodyConfig,
        )
        from ..models.post_v1_registries_by_id_field_defs_body_show_if_type_0 import (
            PostV1RegistriesByIdFieldDefsBodyShowIfType0,
        )

        d = dict(src_dict)
        section_id = d.pop("section_id")

        key = d.pop("key")

        type_ = PostV1RegistriesByIdFieldDefsBodyType(d.pop("type"))

        label = d.pop("label")

        help_ = d.pop("help", UNSET)

        required = d.pop("required", UNSET)

        sort_order = d.pop("sort_order", UNSET)

        _config = d.pop("config", UNSET)
        config: PostV1RegistriesByIdFieldDefsBodyConfig | Unset
        if isinstance(_config, Unset):
            config = UNSET
        else:
            config = PostV1RegistriesByIdFieldDefsBodyConfig.from_dict(_config)

        _visibility = d.pop("visibility", UNSET)
        visibility: PostV1RegistriesByIdFieldDefsBodyVisibility | Unset
        if isinstance(_visibility, Unset):
            visibility = UNSET
        else:
            visibility = PostV1RegistriesByIdFieldDefsBodyVisibility(_visibility)

        def _parse_show_if(
            data: object,
        ) -> None | PostV1RegistriesByIdFieldDefsBodyShowIfType0 | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                show_if_type_0 = PostV1RegistriesByIdFieldDefsBodyShowIfType0.from_dict(data)

                return show_if_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | PostV1RegistriesByIdFieldDefsBodyShowIfType0 | Unset, data)

        show_if = _parse_show_if(d.pop("show_if", UNSET))

        post_v1_registries_by_id_field_defs_body = cls(
            section_id=section_id,
            key=key,
            type_=type_,
            label=label,
            help_=help_,
            required=required,
            sort_order=sort_order,
            config=config,
            visibility=visibility,
            show_if=show_if,
        )

        post_v1_registries_by_id_field_defs_body.additional_properties = d
        return post_v1_registries_by_id_field_defs_body

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
